require "spec_helper"

describe API::EarnedBadgesController do
  let(:world) { World.create.with(:course, :student, :grade, :badge) }
  let(:professor) { create(:course_membership, :professor, course: world.course).user }

  context "as professor" do
    before(:each) { login_user(professor) }

    describe "POST create" do
      it "creates a new student badge from params" do
        params = { earned_badge: { badge_id: world.badge.id, student_id: world.student.id } }
        expect { post :create, params: params.merge(format: :json) }.to \
          change { EarnedBadge.count }.by(1)
      end
    end

    describe "DELETE destroy" do
      it "deletes a badge" do
        earned_badge = create(:earned_badge, grade: world.grade, student: world.student)
        params = { id: earned_badge.id }
        expect { delete :destroy, params: params }.to \
          change { EarnedBadge.count }.by(-1)
        expect(JSON.parse(response.body)).to \
          eq({"message"=>"Earned badge successfully deleted", "success"=>true})
      end

      it "renders error if no badge found to delete" do
        params = { id: 1234 }
        delete :destroy, params: params
        expect(JSON.parse(response.body)).to \
          eq({"message" => "Earned badge failed to delete", "success" => false})
      end
    end
  end

  context "as an unauthenticated user" do
    describe "GET confirm_earned" do
      let(:course) { create(:course) }
      let(:badge) { create(:badge, course: course) }
      let(:earned_badge) { create(:earned_badge, badge: badge, course: course) }

      it "returns a 404 if the course was not found" do
        params = { course_id: "0", badge_id: badge.id, id: earned_badge.id }
        get :confirm_earned, params: params
        expect(response.status).to eq 404
      end

      it "returns a 404 if the badge was not found" do
        params = { course_id: course.id, badge_id: "0", id: earned_badge.id }
        get :confirm_earned, params: params
        expect(response.status).to eq 404
      end

      it "returns a 404 if the earned badge was not found" do
        params = { course_id: course.id, badge_id: badge.id, id: "0" }
        get :confirm_earned, params: params
        expect(response.status).to eq 404
      end

      it "returns a 200 if the earned badge is found" do
        params = { course_id: course.id, badge_id: badge.id, id: earned_badge.id }
        get :confirm_earned, params: params
        expect(response.status).to eq 200
      end
    end
  end
end
