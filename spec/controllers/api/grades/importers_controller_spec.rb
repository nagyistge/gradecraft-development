describe API::Grades::ImportersController, type: [:disable_external_api, :controller] do
  let(:course) { build_stubbed :course }
  let(:provider) { :canvas }
  let(:assignment) { create :assignment, course: course }

  before(:each) do
    login_user(user)
    allow(controller).to receive(:current_course).and_return course
  end

  context "as a professor" do
    let(:user) { build :user, courses: [course], role: :professor }
    let(:access_token) { "topsecret" }
    let(:syllabus) { double(:syllabus, grades: grades, assignment: provider_assignment ) }
    let(:grades) { [{ id: 1, score: 100 }, { id: 2, score: 120 }] }
    let(:provider_assignment) { { name: "Pass/Fail" } }
    let!(:user_authorization) do
      create :user_authorization, :canvas, user: user, access_token: access_token,
        expires_at: 2.days.from_now
    end

    before(:each) do
      allow(ActiveLMS::Syllabus).to receive(:new).with("canvas", access_token).and_return \
        syllabus
    end

    describe "#show" do
      it "returns the assignment, grades, and provider name" do
        get :show, params: { assignment_id: assignment.id, id: course.id, importer_provider_id: provider },
          format: :json
        expect(assigns :assignment).to eq assignment
        expect(assigns :provider_name).to eq "canvas"
        expect(assigns :grades).to eq grades
      end

      it "renders the template" do
        get :show, params: { assignment_id: assignment.id, id: course.id, importer_provider_id: provider },
          format: :json
        expect(response).to render_template "api/grades/importers/show"
      end
    end
  end

  context "as a student" do
    let(:user) { build_stubbed :user, courses: [course], role: :student }

    describe "#show" do
      it "is a protected route" do
        get :show, params: { assignment_id: assignment.id, id: course.id, importer_provider_id: provider },
          format: :json
        expect(response).to have_http_status 302
      end
    end
  end
end
