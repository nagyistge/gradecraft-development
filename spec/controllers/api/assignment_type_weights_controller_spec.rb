describe API::AssignmentTypeWeightsController do
  let(:course) { build :course }
  let(:student)  { create(:course_membership, :student, course: course).user }
  let(:professor) { create(:course_membership, :professor, course: course).user }
  let(:assignment_type) { create(:assignment_type, course: course, student_weightable: true) }

  context "as professor" do
    before(:each) { login_user(professor) }

    describe "POST create" do
      it "is a protected route" do
        expect(post :create,
               params: { assignment_type_id: assignment_type.id, weight: 4 },
               format: :json).to redirect_to(:root)
      end
    end
  end

  context "as student" do
    before(:each) { login_user(student) }

    describe "create" do
      it "returns 400 if the assignment type is not weightable" do
        assignment_type.update(student_weightable: false)
        post :create, params: { assignment_type_id: assignment_type.id, weight: 4 },
          format: :json
        expect(response.status).to eq(404)
      end

      it "updates the student's weight" do
        post :create, params: { assignment_type_id: assignment_type.id, weight: 4 },
          format: :json
        expect(assignment_type.weight_for_student(student)).to eq(4)
      end

      it "updates existing grade scores for the assignment type" do
        assignment = create :assignment, assignment_type: assignment_type
        other_assignment = create :assignment
        grade = create :grade, assignment: assignment, student: student, raw_points: 1000
        other_grade = create :grade, assignment: other_assignment, student: student, raw_points: 333
        post :create, params: { assignment_type_id: assignment_type.id, weight: 4 }, format: :json
        expect(grade.reload.score).to eq(4000)
        expect(other_grade.reload.score).to eq(333)
      end

      it "updates existing course score" do
        assignment = create :assignment, assignment_type: assignment_type
        grade = create :grade, assignment: assignment, student: student, raw_points: 1000, student_visible: true
        post :create, params: { assignment_type_id: assignment_type.id, weight: 4 }, format: :json
        expect(student.score_for_course(course)).to eq(4000)
      end
    end
  end
end
