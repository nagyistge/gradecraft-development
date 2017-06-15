class ChallengeGrade < ActiveRecord::Base
  include GradeStatus

  belongs_to :course
  belongs_to :challenge
  belongs_to :team, autosave: true

  scope :for_course, ->(course) { where(course_id: course.id) }
  scope :for_team, ->(team) { where(team_id: team.id) }

  validates_presence_of :team, :challenge

  delegate :name, :description, :due_at, :full_points, to: :challenge

  releasable_through :challenge

  before_save :calculate_final_points
  before_save :update_challenge_status_fields

  validates :challenge_id, uniqueness: { scope: :team_id }
  validates_presence_of :team_id
  validates_numericality_of :raw_points, :final_points, :adjustment_points, allow_nil: true, length: { maximum: 9 }

  def score
    final_points
  end

  def raw_points
    super.presence || nil
  end

  # totaled points (adds adjustment, without weighting)
  def calculate_final_points
    return nil unless raw_points.present?
    self.final_points = raw_points + adjustment_points
  end

  def cache_team_scores
    team.update_challenge_grade_score!
    team.update_average_score!
  end
end
