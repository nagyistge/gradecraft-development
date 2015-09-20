class AssignmentExportsController < ApplicationController
  before_filter :ensure_staff?
  before_filter :fetch_assignment
  before_filter :fetch_team, only: :submissions_by_team
  respond_to :json

  def submissions
    @presenter = AssignmentExportPresenter.new({
      submissions: @assignment.student_submissions
    })
  end

  def submissions_by_team
    @presenter = AssignmentExportPresenter.new({
      submissions: @assignment.student_submissions_for_team(@team)
    })
  end

  def export
    fetch_assignment
    @submissions ||= @assignment.student_submissions
    group_submissions_by_student
  end

  private
    def group_submissions_by_student
      @submissions_by_student ||= @submissions.group_by do |submission|
        student = submission.student
        "#{student[:last_name]}_#{student[:first_name]}-#{student[:id]}".downcase
      end
    end

    def fetch_assignment
      @assignment = Assignment.find params[:assignment_id]
    end

    def fetch_team
      @team = Team.find params[:team_id]
    end
end
