require "spec_helper"

describe AssignmentTypeWeightsController do
  let(:world) { World.create.with(:course, :student) }
  let(:professor) { create(:course_membership, :professor, course: world.course).user }

  context "as student" do

    before(:each) do
      login_user(world.student)
    end

    describe "GET index" do
      it "returns index page for weights" do
        get :index
        expect(response).to render_template("index")
      end
    end
  end
end
