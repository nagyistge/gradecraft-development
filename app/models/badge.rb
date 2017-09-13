class Badge < ActiveRecord::Base
  include Copyable
  include UnlockableCondition
  include MultipleFileAttributes
  include Analytics::BadgeAnalytics

  acts_as_list scope: :course

  mount_uploader :icon, BadgeIconUploader

  has_many :earned_badges, dependent: :destroy
  has_many :predicted_earned_badges, dependent: :destroy

  belongs_to :course

  accepts_nested_attributes_for :earned_badges, allow_destroy: true, reject_if: proc { |a| a.points.blank? }

  multiple_files :badge_files
  has_many :badge_files, dependent: :destroy, inverse_of: :badge
  accepts_nested_attributes_for :badge_files

  validates_presence_of :course, :name
  validates_numericality_of :full_points, allow_nil: true, length: { maximum: 9 }
  validates_inclusion_of :visible, :can_earn_multiple_times, :visible_when_locked,
    :show_name_when_locked, :show_points_when_locked, :show_description_when_locked,
    in: [true, false], message: "must be true or false"

  scope :visible, -> { where(visible: true) }
  scope :ordered, -> { order("position ASC") }
  scope :accepted, -> { where(state: "Accepted").order("position ASC") }
  scope :rejected, -> { where(state: "Rejected").order("position ASC") }
  scope :proposed, -> { where(state: "Proposed").order("position ASC") }
  scope :earned_this_week, -> { includes(:earned_badges).where("earned_badges.updated_at > ?", 7.days.ago).references(:earned_badges) }

  # Counting how many times a particular student has earned this badge
  def earned_badge_count_for_student(student)
    earned_badges.where(student_id: student.id, student_visible: true).count
  end

  # Can this badge be awarded to a student?
  # Must accound for invisible earned badges
  def available_for_student?(student)
    can_earn_multiple_times ||
    earned_badges.where(student_id: student.id).count < 1
  end
end
