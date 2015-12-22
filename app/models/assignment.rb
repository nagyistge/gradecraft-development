require_relative "concerns/multiple_file_attributes"

class Assignment < ActiveRecord::Base
  include Gradable
  include MultipleFileAttibutes
  include ScoreLevelable
  include UploadsMedia
  include UploadsThumbnails
  include UnlockableCondition

  attr_accessible :name, :assignment_type_id, :assignment_type, :description,
    :point_total, :open_at, :due_at, :accepts_submissions_until,
    :release_necessary, :student_logged, :accepts_submissions, :accepts_links,
    :accepts_text, :accepts_attachments, :resubmissions_allowed, :grade_scope,
    :visible, :visible_when_locked, :required, :pass_fail, :use_rubric,
    :hide_analytics, :points_predictor_display, :notify_released,
    :mass_grade_type, :include_in_timeline, :include_in_predictor,
    :include_in_to_do, :assignment_file_ids,
    :assignment_files_attributes, :assignment_file,
    :assignment_score_levels_attributes, :assignment_score_level, :course

  attr_accessor :current_student_grade

  belongs_to :course, touch: true
  belongs_to :assignment_type, -> { order('position ASC') }, touch: true

  has_one :rubric, dependent: :destroy

  multiple_files :assignment_files

  # For instances where the assignment needs its own unique score levels
  score_levels :assignment_score_levels, -> { order "value" }, dependent: :destroy

  # This is the assignment weighting system (students decide how much assignments will be worth for them)
  has_many :weights, class_name: "AssignmentWeight", dependent: :destroy

  # Student created groups, can connect to multiple assignments and receive group level or individualized feedback
  has_many :assignment_groups, :dependent => :destroy
  has_many :groups, :through => :assignment_groups

  # Multipart assignments
  has_many :tasks, :as => :assignment, :dependent => :destroy

  # Student created submissions to be graded
  has_many :submissions, :dependent => :destroy

  has_many :rubric_grades, :dependent => :destroy

  # Instructor uploaded resource files
  has_many :assignment_files, dependent: :destroy
  accepts_nested_attributes_for :assignment_files

  # Preventing malicious content from being submitted
  before_save :sanitize_description

  # Strip points from pass/fail assignments
  before_save :zero_points_for_pass_fail

  # Check to make sure the assignment has a name before saving
  validates :course_id, presence: true
  validates_presence_of :name
  validates_presence_of :assignment_type_id
  validate :open_before_close, :submissions_after_due, :submissions_after_open

  scope :group_assignments, -> { where grade_scope: "Group" }

  # Filtering Assignments by where in the interface they are displayed
  scope :timelineable, -> { where(:include_in_timeline => true) }

  # Sorting assignments by different properties
  scope :chronological, -> { order('due_at ASC') }
  scope :alphabetical, -> { order('name ASC') }
  acts_as_list scope: :assignment_type

  # Filtering Assignments by various date properties
  scope :with_dates, -> { where('assignments.due_at IS NOT NULL OR assignments.open_at IS NOT NULL') }

  default_scope { order('position ASC') }

  delegate :student_weightable?, to: :assignment_type

  def copy
    copy = self.dup
    copy.name.prepend "Copy of "
    copy.save unless self.new_record?
    copy.assignment_score_levels << self.assignment_score_levels.map(&:copy)
    copy.rubric = self.rubric.copy if self.rubric.present?
    copy
  end

  def to_json(options = {})
    super(options.merge(only: [:id]))
  end

  def point_total
    super.presence || 0
  end

  def has_rubric?
    !! rubric
  end

  def fetch_or_create_rubric
    return rubric if rubric
    Rubric.create assignment_id: self[:id]
  end

  # Checking to see if an assignment is individually graded
  def is_individual?
    !['Group'].include? grade_scope
  end

  # Checking to see if the assignment is a group assignment
  def has_groups?
    grade_scope=="Group"
  end

  # Custom point total if the class has weighted assignments
  def point_total_for_student(student, weight = nil)
    (point_total * weight_for_student(student, weight)).round rescue 0
    # rescue methods with a '0' for pass/fail assignments that are also student weightable for some untold reason
  end

  # Grabbing a student's set weight for the assignment - returns one if the course doesn't have weights
  def weight_for_student(student, weight = nil)
    return 1 unless student_weightable?
    weight ||= (weights.where(student: student).pluck('weight').first || 0)
    weight > 0 ? weight : default_weight
  end

  # Allows instructors to set a value (presumably less than 1) that would be multiplied by *not* weighted assignments
  def default_weight
    course.default_assignment_weight
  end

  # Checking to see if an assignment is due soon
  def soon?
    future? && due_at < 7.days.from_now
  end

  # Setting the grade predictor displays
  def fixed?
    points_predictor_display == "Fixed"
  end

  def slider?
    points_predictor_display == "Slider"
  end

  def select?
    points_predictor_display == "Select List"
  end

  # The below four are the Quick Grading Types, can be set at either the assignment or assignment type level
  def grade_checkboxes?
    mass_grade_type == "Checkbox"
  end

  def grade_select?
    mass_grade_type == "Select List" && has_levels?
  end

  def grade_radio?
    mass_grade_type == "Radio Buttons" && has_levels?
  end

  def grade_text?
    mass_grade_type == "Text"
  end

  def has_levels?
    assignment_score_levels.present?
  end

  # Finding what grade level was earned for a particular assignment
  def grade_level(grade)
    assignment_score_levels.find { |asl| grade.raw_score == asl.value }.try(:name)
  end

  def future?
    !due_at.nil? && due_at >= Time.now
  end

  def opened?
    open_at.nil? || open_at < Time.now
  end

  def overdue?
    !due_at.nil? && due_at < Time.now
  end

  def accepting_submissions?
    accepts_submissions_until.nil? || accepts_submissions_until > Time.now
  end

  # Checking to see if the assignment is still open and accepting submissons
  def open?
    opened? && (!overdue? || accepting_submissions?)
  end

  # Calculating attendance rate, which tallies number of people who have positive grades for attendance divided by the total number of students in the class
  def completion_rate(course)
    return 0 if course.graded_student_count.zero?
   ((grade_count / course.graded_student_count.to_f) * 100).round(2)
  end

  # Counting the percentage of submissions from the entire class
  def submission_rate(course)
    return 0 if course.graded_student_count.zero?
    ((submissions.count / course.graded_student_count.to_f) * 100).round(2)
  end

  # Creating an array with the set of scores earned on the assignment, and
  def percentage_score_earned
    { scores: earned_score_count.collect { |s| { data: s[1], name: s[0] }}}
  end

  private

  def open_before_close
    if (due_at.present? && open_at.present?) && (due_at < open_at)
      errors.add :base, 'Due date must be after open date.'
    end
  end

  def submissions_after_due
    if (accepts_submissions_until.present? && due_at.present?) && (accepts_submissions_until < due_at)
      errors.add :base, 'Submission accept date must be after due date.'
    end
  end

  def submissions_after_open
    if (accepts_submissions_until.present? && open_at.present?) && (accepts_submissions_until < open_at)
      errors.add :base, 'Submission accept date must be after open date.'
    end
  end

  # Stripping the description of extra code
  def sanitize_description
    self.description = Sanitize.clean(description, Sanitize::Config::BASIC)
  end

  def zero_points_for_pass_fail
    self.point_total = 0 if self.pass_fail?
  end
end
