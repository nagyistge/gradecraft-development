class InfoController < ApplicationController
  helper_method :sort_column, :sort_direction, :predictions

  before_action :ensure_not_observer?, except: [:predictor, :syllabus, :tour]
  before_action :ensure_staff?, except: [:dashboard, :predictor, :syllabus, :tour]
  before_action :find_team,
    only: [:earned_badges, :multiplier_choices]
  before_action :find_students,
    only: [:earned_badges, :multiplier_choices, :final_grades_for_course ]
  before_action :use_current_course, only: [:earned_badges, :per_assign, :multiplier_choices, :gradebook]

  # Displays student and instructor dashboard
  def dashboard
    @events = Timeline.new(current_course).events_by_due_date
    render :dashboard, Info::DashboardCoursePlannerPresenter.build({
      student: current_student,
      assignments: current_course.assignments.chronological.includes(:assignment_type, :unlock_conditions),
      course: current_course,
      view_context: view_context
    })
  end

  def syllabus
  end

  # Display the grade predictor
  def predictor
  end

  def tour
    session[:show_tour] = true
    redirect_back_or_default
  end

  def earned_badges
    @teams = @course.teams
    @badges = @course.badges.ordered
  end

  # Displaying ungraded submissions, and existing grades by status
  def grading_status
    grades = current_course.grades.for_active_students.instructor_modified
    submissions = current_course.submissions.submitted.by_active_students.includes(:assignment, :grade, :student, :group, :submission_files)
    @ungraded_submissions_by_assignment = submissions.ungraded
    @resubmissions_by_assignment = submissions.resubmitted
    @in_progress_grades_by_assignment = grades.in_progress
    @ready_for_release_grades_by_assignment = grades.ready_for_release
  end

  # Displaying per assignment summary outcome statistics
  def per_assign
    @assignment_types = @course.assignment_types.ordered.includes(:assignments)
  end

  def export_earned_badges
    course = Course.find_by(id: params[:id])
    respond_to do |format|
      format.csv do
        send_data EarnedBadgeExporter.new.earned_badges_for_course(course.earned_badges),
        filename: "#{course.name} Awarded #{ term_for :badges } - #{ Date.today }.csv"
      end
    end
  end

  def final_grades
    course = current_user.courses.find_by(id: params[:id])
    respond_to do |format|
      format.csv do
        send_data CourseGradeExporter.new.final_grades_for_course(course),
        filename: "#{ course.name } Final Grades - #{ Date.today }.csv"
      end
    end
  end

  def gradebook
  end

  def gradebook_file
    course = current_user.courses.find_by(id: params[:id])
    GradebookExporterJob
      .new(
        user_id: current_user.id,
        course_id: course.id,
        filename: "#{ course.name } Gradebook - #{ Date.today }.csv"
      ).enqueue

    flash[:notice]="Your request to export the gradebook for \"#{ course.name }\" is currently being processed. We will email you the data shortly."
    redirect_back_or_default
  end

  def multiplied_gradebook
    course = current_user.courses.find_by(id: params[:id])
    MultipliedGradebookExporterJob
      .new(user_id: current_user.id, course_id: course.id, filename: "#{ course.name } Multiplied Gradebook - #{ Date.today }.csv").enqueue

    flash[:notice]="Your request to export the multiplied gradebook for \"#{ course.name }\" is currently being processed. We will email you the data shortly."
    redirect_back_or_default
  end

  # downloadable grades for course with  export
  def research_gradebook
    course = current_user.courses.find_by(id: params[:id])
    @grade_export_job = GradeExportJob.new(user_id: current_user.id, course_id: course.id,
    filename: "#{ course.name } Research Gradebook - #{ Date.today }.csv")
    @grade_export_job.enqueue

    flash[:notice]="Your request to export grade data from course \"#{ course.name }\" is currently being processed. We will email you the data shortly."
    redirect_back_or_default
  end

  # Chart displaying all of the student weighting choices thus far
  def multiplier_choices
    @assignment_types = current_course.assignment_types.ordered
    @teams = current_course.teams
  end

  def submissions
    course = current_user.courses.find_by(id: params[:id])
    @submission_export_job = SubmissionExportJob.new(user_id: current_user.id, course_id: course.id, filename: "#{ course.name } Submissions Export - #{ Date.today }.csv")
    @submission_export_job.enqueue

    flash[:notice]="Your request to export submissions from course \"#{ course.name }\" is currently being processed. We will email you the data shortly."
    redirect_back_or_default
  end

  private

  def find_team
    @team = current_course.teams.find_by(id: params[:team_id]) if params[:team_id]
  end

  def find_students
    if @team
      @students = current_course.students_being_graded_by_team(@team).order_by_name
    else
      @students = current_course.students_being_graded.order_by_name
    end
  end
end
