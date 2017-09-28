describe API::Students::BadgesController do
  let(:course) { build :course }
  let(:badge) { create :badge, course: course }
  let(:badge_accepted) { create(:badge, course: course, state: "accepted") }
  let(:badge_rejected) { create(:badge, course: course, state: "rejected") }
  let(:student) { create(:course_membership, :student, course: course).user}
  let(:professor) { create(:course_membership, :professor, course: course).user }

  context "as professor" do
    before(:each) { login_user(professor) }

    describe "GET index" do
      before do
        allow(controller).to receive(:current_course).and_return(course)
        allow(controller).to receive(:current_user).and_return(professor)
      end

      it "assigns the badges with no call to update" do
        get :index, params: { student_id: student.id }, format: :json
        expect(assigns(:student)).to eq(student)
        predictor_badge_attributes do |attr|
          expect(assigns(:badges)[0][attr]).to eq(badge[attr])
        end
        expect(assigns(:update_badges)).to be_falsey
        expect(response).to render_template("api/badges/index")
      end

      it "assigns the student's earned badges" do
        earned_badge = create(
          :earned_badge, badge: badge,
          student: student, course: course, student_visible: true)
        get :index, format: :json, params: { student_id: student.id }
        expect(assigns(:earned_badges)).to eq([earned_badge])
      end

      it "grabs accepted, proposed, rejected badges" do
        earned_badge = create(
          :earned_badge, badge: badge,
          student: student, course: course, student_visible: true)

        earned_badge_accepted = create(
        :earned_badge, badge: badge_accepted,
        student: student, course: course, student_visible: true)

        earned_badge_rejected = create(
          :earned_badge, badge: badge_rejected,
          student: student, course: course, student_visible: true)

        get :index, params: { student_id: student.id, state: "accepted" }, format: :json
        expect(assigns(:badges)).to eq([badge_accepted])

        get :index, params: { student_id: student.id, state: "rejected" }, format: :json
        expect(assigns(:badges)).to eq([badge_rejected])

        get :index, params: { student_id: student.id, state: "proposed" }, format: :json
        expect(assigns(:badges)).to eq([badge])
      end
    end
  end

  # helper methods:
  def predictor_badge_attributes
    [
      :id,
      :name,
      :description,
      :full_points,
      :visible,
      :visible_when_locked,
      :can_earn_multiple_times,
      :position,
      :icon
    ]
  end
end
