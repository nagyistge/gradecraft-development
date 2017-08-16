describe User do
  let(:course) { create(:course) }
  let(:student) { create(:user) }
  let(:course_membership) { create(:course_membership, :student, user: student, course: course) }
  let(:grade_scheme_element) { create(:grade_scheme_element, course: course)}
  let(:assignment) { create(:assignment, course: course) }
  let(:grade) { create(:grade, assignment: assignment, course: course, student: student) }

  describe "#update_course_score_and_level" do
    subject { student.update_course_score_and_level(course.id) }

    context "course membership is present" do
      before(:each) { allow(student).to receive(:course_membership) { course_membership } }

      it "returns the the recalculated student score" do
        allow(course_membership).to receive(:recalculate_and_update_student_score) { 58000 }
        expect(subject).to eq(true)
      end

      it "returns the the recalculated student level" do
        allow(course_membership).to receive(:check_and_update_student_earned_level) { :grade_scheme_element }
        expect(subject).to eq(true)
      end
    end

    context "course membership is nil" do
      before(:each) { allow(student).to receive(:course_membership) { nil } }

      it "doesn't recalculate the student score" do
        expect(course_membership).not_to receive(:recalculate_and_update_student_score)
        subject
      end

      it "returns nil" do
        expect(subject).to eq(nil)
      end
    end
  end
end
