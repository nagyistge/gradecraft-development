# rubocop:disable AndOr
class UserSessionsController < ApplicationController

  before_action :ensure_staff?, only: [:impersonate_student]
  skip_before_action :require_login, except: [:index]
  skip_before_action :require_course_membership, except: :index
  skip_before_action :verify_authenticity_token, only: [:lti_create]

  def new
    @user = User.new
  end

  def instructors
    redirect_back_or_default and return if Rails.env.production?
    @user = User.new
  end

  # sorcery login - users have passwords stored in our db
  def create
    respond_to do |format|
      if @user = login(params[:user][:email].downcase, params[:user][:password])
        record_course_login_event user: @user
        format.html { redirect_back_or_to current_user_is_observer? ? assignments_path : dashboard_path }
        format.xml { render xml: @user, status: :created, location: @user }
      else
        @user = User.new
        format.html do
          flash.now[:error] = "Email or Password were invalid, login failed.";
          render action: "new"
        end
        format.xml { render xml: @user.errors, status: :unprocessable_entity }
      end
    end
  end

  # rubocop:disable AndOr
  # lti login - we do not record users passwords, they login via an outside app
  def lti_create
    result = Services::CreatesOrUpdatesUserFromLTI.create_or_update(auth_hash)
    redirect_to errors_path(error_type: "lti_auth_with_email_but_not_name_info", status_code: result.error_code) \
      and return unless result.success?

    @user = result[:user]
    @course = Services::CreatesOrUpdatesCourseFromLTI.create_or_update(auth_hash, false)[:course]
    if !@user || !@course
      lti_error_notification
      flash[:alert] = t("sessions.create.error")
      redirect_to auth_failure_path
      return
    end
    # TODO: should we rollback user, course creation if the course membership cannot be created?
    if CourseMembership.create_or_update_from_lti(@user, @course, auth_hash)
      save_lti_context
      session[:course_id] = @course.id
      auto_login @user
      record_course_login_event user: @user
      respond_with @user, location: dashboard_path
    else
      redirect_to root_path, alert: "An unknown error occurred."
    end
  end

  def impersonate_student
    student = current_course.students.find(params[:student_id]) unless params[:student_id] == "0"
    impersonate! student
    redirect_to root_url
  end

  def exit_student_impersonation
    unimpersonate!
    redirect_to students_path
  end

  def destroy
    logout
    redirect_to root_url, notice: "You are now logged out. Thanks for playing!"
  end

  private

  def auth_hash
    request.env["omniauth.auth"]
  end

  def lti_error_notification
    user = { name: auth_hash["extra"]["raw_info"]["lis_person_name_full"], email: auth_hash["extra"]["raw_info"]["lis_person_contact_email_primary"], lti_uid: auth_hash["extra"]["raw_info"]["context_id"] }
    course = { name: auth_hash["extra"]["raw_info"]["context_label"], uid: auth_hash["extra"]["raw_info"]["context_id"] }
    NotificationMailer.lti_error(user, course).deliver_now
  end

  def redirect_back_or(default)
    redirect_to(session[:return_to] || default)
    clear_return_to
  end
end
