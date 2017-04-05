class API::AssignmentsController < ApplicationController
  before_action :ensure_staff?, only: [:show, :update]

  # GET api/assignments
  def index
    @assignments = current_course.assignments.ordered

    if current_user_is_student?
      @student = current_student
      @allow_updates = !impersonating? && current_course.active?
      @grades = Grade.for_course(current_course).for_student(current_student)

      if !impersonating?
        @assignments.includes(:predicted_earned_grades)
        @predicted_earned_grades =
          PredictedEarnedGrade.for_course(current_course).for_student(current_student)
      end
    end
  end

  # GET api/assignments/:id
  def show
    @assignment = Assignment.find(params[:id])
  end

  # POST api/assignments/:id
  def update
    @assignment = Assignment.find(params[:id])
    if @assignment.update_attributes assignment_params
      render "api/assignments/show", success: true, status: 200
    else
      render json: {
        message: "failed to save assignment", success: false
        }, status: 400
    end
  end

  # optional student for graph point:
  # /api/assignments/:assignment_id/analytics
  # /api/assignments/:assignment_id/analytics?student_id=:student_id
  def analytics
    @assignment = Assignment.find(params[:assignment_id])
    @user_score = @assignment.score_for params[:student_id], current_user if params[:student_id].present?
  end

  private

  def assignment_params
    params.require(:assignment).permit(
      :accepts_submissions, :include_in_predictor, :include_in_timeline,
      :include_in_to_do, :release_necessary, :required, :student_logged, :visible
    )
  end
end
