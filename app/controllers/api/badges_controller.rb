class API::BadgesController < ApplicationController
  include SortsPosition

  before_action :ensure_not_observer?, only: [:create, :update]
  before_action :ensure_staff?, except: [:index, :create, :update]

  # GET api/badges
  def index
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
      :visible_when_locked,
      :state)

    return unless params[:state].present?
      @badges = badges_by_state

    if current_user_is_student?
      @student = current_student
      @allow_updates = !impersonating? && current_course.active?

      if !impersonating?
        @badges.includes(:predicted_earned_badges)
        @predicted_earned_badges =
          PredictedEarnedBadge.for_course(current_course).for_student(current_student)
      end
    end
  end

  def show
    @badge = Badge.find(params[:id])
  end

  # PUT api/badges/:id
  def update
    @badge = Badge.find(params[:id])
    if @badge.update_attributes badge_params
      render "api/badges/show", success: true, status: 200
    else
      render json: {
        message: "failed to save badge",
        errors: @badge.errors.messages,
        success: false
        }, status: 400
    end
  end

  def create
    @badge = current_course.badges.new(badge_params.merge(created_by: current_user.id))
    if current_user_is_staff?
      @badge.state = "accepted"
    end
    if @badge.save
      render "api/badges/show", success: true, status: 201
    else
      render json: {
        message: "failed to save badge",
        errors: @badge.errors.messages,
        success: false
        }, status: 400
    end
  end

  def sort
    sort_position_for :badge
  end

  private

  def badges_by_state
    if params[:state] == "accepted"
      @badges = @badges.accepted
    end
  end

  def badge_params
    params.require(:badge).permit(
      :can_earn_multiple_times,
      :description,
      :full_points,
      :icon,
      :name,
      :position,
      :remove_icon,
      :show_description_when_locked,
      :show_name_when_locked,
      :show_points_when_locked,
      :student_awardable,
      :visible,
      :visible_when_locked,
      :created_by
    )
  end
end
