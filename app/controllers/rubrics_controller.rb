class RubricsController < ApplicationController
  before_action :ensure_staff?, except: [:export]
  before_action :use_current_course, only: [:edit]

  respond_to :html, :json

  def edit
    @assignment = current_course.assignments.find params[:assignment_id]
    @rubric = @assignment.find_or_create_rubric
    @course_badge_count = @assignment.course.badges.visible.count
    respond_with @rubric
  end

  def destroy
    @rubric = @assignment.rubric
    @rubric.destroy
    respond_with @rubric
  end

  def index_for_copy
    @assignment = Assignment.find(params[:assignment_id])
    @rubrics = Rubric.where(assignment_id: current_course.assignments.pluck(:id))
  end

  def copy
    assignment = Assignment.find(params[:assignment_id])
    # remove any rubric added via find_or_create_rubric
    assignment.rubric.destroy if assignment.rubric.present?

    Rubric.find(params[:rubric_id]).copy(assignment_id: assignment.id)
    redirect_to edit_assignment_path(assignment),
      notice: "Added rubric to #{(term_for :assignment).titleize} #{assignment.name}"
  end

  def export
    assignment = current_course.assignments.find params[:assignment_id]
    rubric = assignment.rubric
    respond_to do |format|
      format.csv { send_data RubricExporter.new.export(rubric), filename: "#{assignment.name} Rubric.csv" }
    end
  end
end
