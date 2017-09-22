class API::Students::BadgesController < ApplicationController

  before_action :ensure_staff?

  # GET api/students/:student_id/badges
  def index
    @student = User.find(params[:student_id])
    @allow_updates = false
    @badges = current_course.badges.ordered.select(
      :can_earn_multiple_times,
      :course_id,
      :description,
      :full_points,
      :icon,
      :id,
      :name,
      :position,
      :visible,
      :visible_when_locked).includes(:earned_badges)
    @earned_badges = current_course.earned_badges.where(student_id: @student.id)

    return unless params[:state].present?
      @badges = badges_by_state

    render template: "api/badges/index"
  end

  private

  def badges_by_state
    if params[:state] == "accepted"
      return @badges.accepted
    end
  end
end
