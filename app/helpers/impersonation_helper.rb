module ImpersonationHelper
  IMPERSONATING_STUDENT = User.find_by(
    first_name: "John",
    last_name: "Doe",
    username: "john_doe_gradecraft",
    email: "john_doe@gradecraft.com").freeze

  def impersonate!(user)
    self.impersonating_agent = current_user
    user = user || IMPERSONATING_STUDENT
    ensure_impersonated_course_access if user == IMPERSONATING_STUDENT
    auto_login user
  end

  def unimpersonate!
    return unless impersonating_agent
    user = current_user
    auto_login impersonating_agent
    delete_impersonating_agent user
  end

  def impersonating_agent
    User.find(impersonating_agent_id) if impersonating?
  end

  def impersonating_agent=(user)
    session[:impersonating_agent_id] = user.id
  end

  def delete_impersonating_agent(user)
    destroy_impersonated_course_access if user == IMPERSONATING_STUDENT
    session.delete :impersonating_agent_id
  end

  def impersonating_agent_id
    session[:impersonating_agent_id]
  end

  def impersonating?
    impersonating_agent_id.present?
  end

  def destroy_impersonated_course_access
    course_membership = current_course.course_memberships.find_by user_id: IMPERSONATING_STUDENT.id,
      role: :student
    course_membership.destroy unless course_membership.nil?
  end

  private

  def ensure_impersonated_course_access
    current_course.course_memberships.find_or_create_by user_id: IMPERSONATING_STUDENT.id,
      role: :student
  end
end
