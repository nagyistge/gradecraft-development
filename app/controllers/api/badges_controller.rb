class API::BadgesController < ApplicationController

  # GET api/badges
  def index
    @badges = current_course.badges.select(
      :can_earn_multiple_times,
      :course_id,
      :description,
      :icon,
      :id,
      :name,
      :full_points,
      :position,
      :visible,
      :visible_when_locked)
  end
end
