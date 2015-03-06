class AssignmentsController < ApplicationController

  before_filter :ensure_staff?, :except => [:feed, :show, :index, :guidelines]

  respond_to :html, :json

  def index
    if current_user_is_student?
      redirect_to syllabus_path
    else
      @title = "#{term_for :assignments}"
      @assignment_types = current_course.assignment_types.sorted
      @assignments = current_course.assignments.includes(:rubric)

      respond_to do |format|
        format.html
        format.csv { send_data @assignments.csv_for_course(current_course) }
      end
    end
  end

  #Gives the instructor the chance to quickly check all assignment settings for the whole course
  def settings
    @title = "Review #{term_for :assignment} Settings"
    @assignments = current_course.assignments.chronological.alphabetical
  end

  def show
    @assignment = current_course.assignments.find(params[:id])
    @assignment_type = @assignment.assignment_type
    @title = @assignment.name
    @groups = @assignment.groups

    # Returns a hash of grades given for the assignment in format of {student_id: grade}
    @assignment_grades_by_student_id = current_course_data.assignment_grades(@assignment)

    @team = current_course.teams.find_by(id: params[:team_id]) if params[:team_id]
    if @team
      students = current_course.students_being_graded_by_team(@team)
    else
      students = current_course.students_being_graded
    end
    user_search_options = {}
    user_search_options['team_memberships.team_id'] = params[:team_id] if params[:team_id].present?
    @students = students

    @auditing = current_course.students_auditing.includes(:teams).where(user_search_options)
    if @assignment.rubric.present?
      @rubric = @assignment.fetch_or_create_rubric
      @metrics = @rubric.metrics
    end
    @course_badges = serialized_course_badges
    @assignment_score_levels = @assignment.assignment_score_levels.order_by_value
    @course_student_ids = current_course.students.map(&:id)

    # Data for displaying student grading distribution
    @submissions_count = @assignment.submissions.count
    @ungraded_submissions_count = @assignment.ungraded_submissions.count
    @ungraded_percentage = @ungraded_submissions_count / @submissions_count rescue 0
    @graded_count = @submissions_count - @ungraded_submissions_count

    if current_user_is_student?
      @grades_for_assignment = @assignment.grades_for_assignment(current_student)
      @rubric_grades = RubricGrade.joins("left outer join submissions on submissions.id = rubric_grades.submission_id").where(student_id: current_user[:id]).where(assignment_id: params[:id])
      @comments_by_metric_id = @rubric_grades.inject({}) do |memo, rubric_grade|
        memo.merge(rubric_grade.metric_id => rubric_grade.comments)
      end
      if @assignment.has_groups? && current_student.group_for_assignment(@assignment).present?
        @group = current_student.group_for_assignment(@assignment)
      end
    else
      @grades_for_assignment = @assignment.all_grades_for_assignment
    end

    #used to display an alternate view of the same content
    render :detailed_grades if params[:detailed]
  end

  def guidelines
    @assignment = current_course.assignments.find(params[:id])
    @title = @assignment.name
    @rubric = @assignment.fetch_or_create_rubric
    @metrics = @rubric.metrics
  end

  # TODO: verify not used and remove
  def rules
    @assignment = current_course.assignments.find(params[:id])
    @title = @assignment.name
  end

  def new
    @title = "Create a New #{term_for :assignment}"
    @assignment = current_course.assignments.new
  end

  def edit
    @assignment = current_course.assignments.find(params[:id])
    @title = "Editing #{@assignment.name}"
  end

  # Duplicate an assignment - important for super repetitive items like attendance and reading reactions
  def copy
    session[:return_to] = request.referer
    @assignment = current_course.assignments.find(params[:id])
    new_assignment = @assignment.dup
    new_assignment.name.prepend("Copy of ")
    new_assignment.save
    if @assignment.assignment_score_levels.present?
      @assignment.assignment_score_levels.each do |asl|
        new_asl = asl.dup
        new_asl.assignment_id = new_assignment.id
        new_asl.save
      end
    end
    if session[:return_to].present?
      redirect_to session[:return_to]
    else
      redirect_to assignments #TODO change to assignments_path
    end
  end

  def create
    if params[:assignment][:assignment_files_attributes].present?
      @assignment_files = params[:assignment][:assignment_files_attributes]["0"]["file"]
      params[:assignment].delete :assignment_files_attributes
    end

    @assignment = current_course.assignments.new(params[:assignment])
    if @assignment_files
      @assignment_files.each do |af|
        @assignment.assignment_files.new(file: af, filename: af.original_filename)
      end
    end
    respond_to do |format|
      if @assignment.save
        set_assignment_weights
        format.html { respond_with @assignment, notice: "#{(term_for :assignment).titleize}  #{@assignment.name} successfully created" }
      else
        # TODO: refactor, see submissions_controller
        @title = "Create a New #{term_for :assignment}"
        format.html {render :action => "new", :group => @group }
      end
    end
  end

  def update
    if params[:assignment][:assignment_files_attributes].present?
      @assignment_files = params[:assignment][:assignment_files_attributes]["0"]["file"]
      params[:assignment].delete :assignment_files_attributes
    end

    @assignment = current_course.assignments.includes(:assignment_score_levels).find(params[:id])

    if @assignment_files
      @assignment_files.each do |af|
        @assignment.assignment_files.new(file: af, filename: af.original_filename)
      end
    end

    respond_to do |format|

      if @assignment.update_attributes(params[:assignment])
        set_assignment_weights
        format.html { redirect_to assignments_path, notice: "#{(term_for :assignment).titleize}  #{@assignment.name} successfully updated" }
      else
        # TODO: refactor, see submissions_controller
        @title = "Edit #{term_for :assignment}"
        format.html {render :action => "edit", :group => @group }
      end
    end
  end

  def sort
    params[:"assignment"].each_with_index do |id, index|
      current_course.assignments.update(id, position: index + 1)
    end
    render nothing: true
  end

  def update_rubrics
    @assignment = current_course.assignments.find params[:id]
    @assignment.update_attributes use_rubric: params[:use_rubric]
    respond_with @assignment
  end

  def rubric_grades_review
    @assignment = current_course.assignments.find(params[:id])
    @title = @assignment.name
    @groups = @assignment.groups

    @team = current_course.teams.find_by(id: params[:team_id]) if params[:team_id]
    if @team
      students = current_course.students_being_graded_by_team(@team)
    else
      students = current_course.students_being_graded
    end
    user_search_options = {}
    user_search_options['team_memberships.team_id'] = params[:team_id] if params[:team_id].present?
    @students = students

    @auditing = current_course.students_auditing.includes(:teams).where(user_search_options)

    @rubric = @assignment.fetch_or_create_rubric
    @metrics = @rubric.metrics
    @course_badges = serialized_course_badges
    @assignment_score_levels = @assignment.assignment_score_levels.order_by_value
    @course_student_ids = current_course.students.map(&:id)


    @rubric_grades = serialized_rubric_grades

    @viewable_rubric_grades = RubricGrade.where(assignment_id: @assignment.id)
    @comments_by_metric_id = @viewable_rubric_grades.inject({}) do |memo, rubric_grade|
      memo.merge(rubric_grade.metric_id => rubric_grade.comments)
    end

  end

  private

  def serialized_rubric_grades
    ActiveModel::ArraySerializer.new(fetch_rubric_grades, each_serializer: ExistingRubricGradesSerializer).to_json
  end

  def fetch_rubric_grades
    RubricGrade.where(fetch_rubric_grades_params)
  end

  def fetch_rubric_grades_params
    { student_id: params[:student_id], assignment_id: params[:assignment_id], metric_id: existing_metric_ids }
  end

  def existing_metric_ids
    rubric_metrics_with_tiers.collect {|metric| metric[:id] }
  end

  public

  def destroy
    @assignment = current_course.assignments.find(params[:id])
    @name = @assignment.name
    @assignment.destroy
    redirect_to assignments_url, notice: "#{(term_for :assignment).titleize} #{@name} successfully deleted"
  end

  # Calendar feed of assignments
  def feed
    @assignments = current_course.assignments
    respond_with @assignments.with_due_date do |format|
      format.ics do
        render :text => CalendarBuilder.new(:assignments => @assignments.with_due_date ).to_ics, :content_type => 'text/calendar'
      end
    end
  end

  # Export an example for grade imports
  def email_based_grade_import
    @assignment = current_course.assignments.find(params[:id])
    respond_to do |format|
      format.csv { send_data @assignment.email_based_grade_import(@assignment) }
    end
  end

  def username_based_grade_import
    @assignment = current_course.assignments.find(params[:id])
    respond_to do |format|
      format.csv { send_data @assignment.username_based_grade_import(@assignment) }
    end
  end

  # Exporting the grades for a single assignment
  def export_grades
    @assignment = current_course.assignments.find(params[:id])
    respond_to do |format|
      format.csv { send_data @assignment.gradebook_for_assignment(@assignment) }
    end
  end

  private

  def find_or_create_assignment_rubric
    @assignment.rubric || Rubric.create(assignment_id: @assignment[:id])
  end

  def assignment_params
    params.require(:assignment).permit(:assignment_rubrics_attributes => [:id, :rubric_id, :_destroy])
  end

  def set_assignment_weights
    return unless @assignment.student_weightable?
    @assignment.weights = current_course.students.map do |student|
      assignment_weight = @assignment.weights.where(student: student).first || @assignment.weights.new(student: student)
      assignment_weight.weight = @assignment.assignment_type.weight_for_student(student)
      assignment_weight
    end
    @assignment.save
  end

  def serialized_course_badges
    ActiveModel::ArraySerializer.new(course_badges, each_serializer: CourseBadgeSerializer).to_json
  end

  def course_badges
    @course_badges ||= @assignment.course.badges.visible
  end

  def existing_metrics_as_json
    ActiveModel::ArraySerializer.new(rubric_metrics_with_tiers, each_serializer: ExistingMetricSerializer).to_json
  end

  def rubric_metrics_with_tiers
    @rubric.metrics.order(:order).includes(:tiers)
  end

end
