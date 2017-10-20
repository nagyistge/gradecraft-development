describe UserSessionsController do
  let(:course) { create :course }
  let(:student) { create(:course_membership, :student, course: course).user }
  let(:professor) { create(:course_membership, :professor, course: course).user }

  describe "POST create" do
    context "user is successfully logged in" do
      before(:each) { allow(subject).to receive(:login) { student } }

      it "records the course login event" do
        expect(subject).to receive(:record_course_login_event)
        post :create, params: { user: student.attributes }
      end

      it "redirects to dashboard if the current user is not an observer" do
        allow(subject).to receive(:current_user_is_observer?).and_return false
        expect(post :create, params: { user: student.attributes }).to redirect_to \
          dashboard_path
      end

      it "redirects to assignments show page if the current user is an observer" do
        allow(subject).to receive(:current_user_is_observer?).and_return true
        expect(post :create, params: { user: student.attributes }).to redirect_to \
          assignments_path
      end
    end

    context "user is not logged in" do
      it "does not record the course login event" do
        allow(subject).to receive(:login) { nil }
        expect(subject).to_not receive(:record_course_login_event)
        post :create, params: { user: student.attributes }
      end
    end
  end

  describe "lti_create" do
    let(:user_create_result) { { user: user } }
    let(:user) { build_stubbed(:user) }
    let(:course) { create(:course) }

    before(:each) do
      allow(subject).to receive(:auth_hash).and_return params
      allow(user_create_result).to receive(:success?).and_return true
      allow(Services::CreatesOrUpdatesUserFromLTI).to receive(:create_or_update).with(params).and_return user_create_result
      allow(Services::CreatesOrUpdatesCourseFromLTI).to receive(:create_or_update).with(params, false).and_return({ course: course })
    end

    context "when there is no context role" do
      let(:params) { OmniAuth::AuthHash.new("extra" => { "raw_info" => { "roles" => "" }}) }

      it "redirects to dashboard" do
        expect(post :lti_create, params: params).to redirect_to dashboard_path
      end
    end

    context "when there is a context role" do
      let(:params) { OmniAuth::AuthHash.new("extra" => { "raw_info" => { "roles" => "instructor" }}) }

      it "redirects to dashboard" do
        expect(post :lti_create, params: params).to redirect_to dashboard_path
      end
    end

    context "when the course membership creation fails" do
      let(:params) { OmniAuth::AuthHash.new("extra" => { "raw_info" => { "roles" => "instructor" }}) }

      before(:each) { allow(CourseMembership).to receive(:create_or_update_from_lti).and_return false }

      it "redirects to root" do
        expect(post :lti_create, params: params).to redirect_to root_path
      end
    end

    context "when the user creation fails" do
      let(:params) { OmniAuth::AuthHash.new("extra" => { "raw_info" => { "roles" => "instructor" }}) }

      before(:each) { allow(user_create_result).to receive(:success?).and_return false }

      it "redirects to the errors path" do
        allow(user_create_result).to receive(:message).and_return "An error occurred"
        allow(user_create_result).to receive(:error_code).and_return "400"
        expect(post :lti_create, params: params).to redirect_to errors_path(error_type: "lti_auth_with_email_but_not_name_info",
          status_code: user_create_result.error_code)
      end
    end
  end

  describe "impersonate_student" do
    before do
      allow(subject).to receive(:current_course) { course }
    end

    it "stores the professor id in sessions" do
      login_user(professor)
      get :impersonate_student, params: { student_id: student.id }
      expect(session[:impersonating_agent_id]).to eq(professor.id)
    end

    it "logs in as student" do
      login_user(professor)
      get :impersonate_student, params: { student_id: student.id }
      expect(session[:user_id]).to eq(student.id.to_s)
    end
  end

  describe "exit_student_impersonation" do
    it "returns session to faculty" do
      allow(subject).to receive(:current_user).and_return student
      session[:impersonating_agent_id] = professor.id
      get :exit_student_impersonation
      expect(session[:impersonating_agent_id]).to be_nil
      expect(session[:user_id]).to eq(professor.id.to_s)
    end
  end
end
