class NotificationMailer < ApplicationMailer
  layout "mailers/notification_layout"

  def lti_error(user_data, course_data)
    @user_data = user_data
    @course_data = course_data
    send_admin_email "Unknown LTI user/course"
  end

  def successful_submission(submission_id)
    send_assignment_email_to_user submission_id, "Submitted"
  end

  def updated_submission(submission_id)
    send_assignment_email_to_user submission_id, "Submission Updated"
  end

  def new_submission(submission_id, professor)
    send_assignment_email_to_professor professor, submission_id, "New Submission to Grade"
  end

  def revised_submission(submission_id, professor)
    send_assignment_email_to_professor professor, submission_id, "Updated Submission to Grade"
  end

  def grade_released(grade_id)
    set_grade_ivars(grade_id)
    send_student_email "#{@course.courseno} - #{@assignment.name} Graded"
  end

  def earned_badge_awarded(earned_badge_id)
    @earned_badge = EarnedBadge.find earned_badge_id
    @student = @earned_badge.student
    @course = @earned_badge.course
    send_student_email "#{@course.courseno} - You've earned a new #{@course.badge_term}!"
  end

  def group_status_updated(group_id)
    @group = Group.find group_id
    @course = @group.course
    @group_members = @group.students
    @group_members.each do |gm|
      mail(to: gm.email, subject: "#{@course.courseno} - Group #{@group.approved}") do |format|
        @student = gm
        format.text
        format.html
      end
    end
  end

  def group_notify(group_id)
    @group = Group.find group_id
    @course = @group.course
    @group_members = @group.students
    @group_members.each do |gm|
      mail(to: gm.email, subject: "#{@course.courseno} - New Group") do |format|
        @student = gm
        format.text
        format.html
      end
    end
  end

  private

  def send_assignment_email_to_professor(professor, submission_id, subject)
    set_submission_ivars_with_student(submission_id)
    @professor = professor
    mail(to: @professor.email, subject: "#{@course[:courseno]} - #{@assignment.name} - #{subject}") do |format|
      format.text
      format.html
    end
  end

  def send_assignment_email_to_user(submission_id, subject)
    set_submission_ivars_with_user(submission_id)
    mail(to: @user.email, subject: "#{@course.courseno} - #{@assignment.name} #{subject}") do |format|
      format.text
      format.html
    end
  end

  def send_student_email(subject)
    mail(to: @student.email, subject: subject) do |format|
      format.text
      format.html
    end
  end

  def send_admin_email(subject)
    mail(to: ADMIN_EMAIL, subject: subject) do |format|
      format.text
      format.html
    end
  end

  def set_grade_ivars(grade_id)
    @grade = Grade.find grade_id
    @student = @grade.student
    @course = @grade.course
    @assignment = @grade.assignment
  end

  def set_submission_ivars_with_student(submission_id)
    set_submission_ivars(submission_id)
    @student = @submission.student
  end

  def set_submission_ivars_with_user(submission_id)
    set_submission_ivars(submission_id)
    @user = @submission.student
  end

  def set_submission_ivars(submission_id)
    @submission = Submission.find submission_id
    @course = @submission.course
    @assignment = @submission.assignment
  end
end
