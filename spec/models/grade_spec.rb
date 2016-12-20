require "active_record_spec_helper"
require "toolkits/historical_toolkit"
require "toolkits/sanitization_toolkit"
require_relative "../support/uni_mock/rails"

describe Grade do
  include UniMock::StubRails

  before { stub_env "development" }

  subject { build(:grade) }

  describe "constants" do
    describe "STATUSES" do
      it "returns an array of all the status values" do
        expect(described_class::STATUSES).to eq ["In Progress", "Graded", "Released"]
      end
    end

    describe "UNRELEASED_STATUSES" do
      it "returns an array of all the status values" do
        expect(described_class::UNRELEASED_STATUSES).to eq ["In Progress", "Graded"]
      end
    end
  end

  describe "validations" do
    it "is valid with an assignment, student, assignment_type, and course" do
      expect(subject).to be_valid
    end

    it "is invalid without an assignment" do
      subject.assignment = nil
      expect{ subject.save! }.to raise_error Module::DelegationError
    end

    it "is invalid without a student" do
      subject.student = nil
      expect(subject).to_not be_valid
      expect(subject.errors[:student]).to include "can't be blank"
    end

    it "is invalid without a course" do
      subject.assignment.course = nil
      subject.course = nil
      expect(subject).to_not be_valid
      expect(subject.errors[:course]).to include "can't be blank"
    end

    it "is invalid without an assignment type" do
      subject.assignment.assignment_type = nil
      expect(subject).to_not be_valid
      expect(subject.errors[:assignment_type]).to include "can't be blank"
    end

    it "does not allow duplicate grades per student" do
      subject.save!
      another_grade = build(:grade, course: subject.course, assignment: subject.assignment, student: subject.student)
      expect(another_grade).to_not be_valid
      expect(another_grade.errors[:student_id]).to include "has already been graded on this assignment"
    end
  end

  it_behaves_like "a historical model", :grade, raw_points: 1234
  it_behaves_like "a model that needs sanitization", :feedback

  describe "#squish_history!", versioning: true do
    it "squishes two previous changes into one" do
      subject.save!
      subject.update_attributes raw_points: 13_000
      subject.squish_history!
      subject.update_attributes feedback: "This is a change"
      subject.squish_history!
      expect(subject.versions.count).to eq 2
      expect(subject.versions.last.changeset).to have_key :feedback
      expect(subject.versions.last.changeset).to have_key :raw_points
    end
  end

  describe "#raw_points" do
    it "converts raw_points from human readable strings" do
      subject.update(raw_points: "1,234")
      expect(subject.raw_points).to eq(1234)
    end

    it "is converts blank string to nil" do
      subject.update(raw_points: "")
      expect(subject.raw_points).to eq(nil)
    end
  end

  describe ".not_released" do
    it "returns all grades that are graded but require a release" do
      assignment = create :assignment, release_necessary: true
      not_released_grade = create :grade, assignment: assignment, status: "Graded"
      create :grade, assignment: assignment, status: "Released"
      create :grade, status: "Graded"

      expect(described_class.not_released).to eq [not_released_grade]
    end
  end

  describe ".released" do
    it "returns all the grades that are released" do
      released_grade = create :grade, status: "Released"
      create :grade, status: "In Progress"

      expect(described_class.released).to eq [released_grade]
    end
  end

  describe ".student_visible" do
    it "returns all grades that were released or were graded but no release was necessary" do
      graded_grade = create :grade, status: "Graded"
      released_grade = create :grade, status: "Released"
      assignment = create :assignment, release_necessary: true
      create :grade, assignment: assignment, status: "Graded"

      expect(described_class.student_visible).to include(released_grade, graded_grade)
    end
  end

  describe ".releasable_through" do
    it "returns assignment" do
      expect(described_class.releasable_relationship).to eq :assignment
    end
  end

  describe "calculation of final_points" do
    it "is nil when raw_points is nil" do
      subject.update(raw_points: nil)
      expect(subject.final_points).to eq(nil)
    end

    it "is the sum of raw_points and adjustment_points" do
      subject.update(raw_points: "1234", adjustment_points: -234)
      expect(subject.final_points).to eq(1000)
    end

    it "is 0 if the score is below the threshold" do
      subject.assignment.update(threshold_points: 1001)
      subject.update(raw_points: 1000)
      expect(subject.final_points).to eq(0)
    end
  end

  describe "calculating score" do
    it "is nil when raw_points is nil" do
      subject.update(raw_points: nil)
      expect(subject.score).to eq(nil)
    end

    it "is the same as final score when assignment isn't weighted" do
      subject.update(raw_points: "1234", adjustment_points: -234)
      expect(subject.score).to eq(1000)
    end

    it "is the final score weighted by the students weight for the assignment" do
      subject.assignment.assignment_type.update(student_weightable: true)
      create(:assignment_type_weight, student: subject.student, assignment_type: subject.assignment_type, weight: 3 )
      subject.update(raw_points: "1,234", adjustment_points: -234)
      expect(subject.score).to eq(3000)
    end
  end

  describe "when assignment is pass-fail" do
    before do
      subject.assignment.update(pass_fail: true)
    end

    it "saves the grades as zero" do
      subject.save!
      expect(subject.raw_points).to be 0
      expect(subject.final_points).to be 0
      expect(subject.full_points).to be 0
    end
  end

  describe "#feedback_read!" do
    it "marks the grade as read" do
      subject.feedback_read!
      expect(subject).to be_feedback_read
      elapsed = ((DateTime.now - subject.feedback_read_at.to_datetime) * 24 * 60 * 60).to_i
      expect(elapsed).to be < 5
    end
  end

  describe "#feedback_reviewed!" do
    it "marks the grade as reviewed" do
      subject.feedback_reviewed!
      expect(subject).to be_feedback_reviewed
      elapsed = ((DateTime.now - subject.feedback_reviewed_at.to_datetime) * 24 * 60 * 60).to_i
      expect(elapsed).to be < 5
    end
  end

  describe ".for_course" do
    it "returns all grades for a specific course" do
      course = create(:course)
      course_grade = create(:grade, course: course)
      another_grade = create(:grade)
      results = Grade.for_course(course)
      expect(results).to eq [course_grade]
    end
  end

  describe ".for_student" do
    it "returns all grades for a specific student" do
      student = create(:user)
      student_grade = create(:grade, student: student)
      another_grade = create(:grade)
      results = Grade.for_student(student)
      expect(results).to eq [student_grade]
    end
  end

  describe ".for_student_email_and_assignment_id" do
    let(:assignment) { create :assignment }
    let(:email_address) { "jimmy@example.com" }
    let!(:grade) { create :grade, assignment: assignment, student: student }
    let(:student) { create :user, email: email_address }

    it "returns the grade for the specified student email and assignment id" do
      expect(
        described_class.for_student_email_and_assignment_id(email_address.upcase,
                                                            assignment.id)).to eq grade
    end

    it "returns nil if the specified student email does not exist" do
      expect(
        described_class.for_student_email_and_assignment_id("blah", assignment.id)
      ).to be_nil
    end

    it "returns nil if the specified student email is nil" do
      expect(
        described_class.for_student_email_and_assignment_id(nil, assignment.id)
      ).to be_nil
    end
  end

  describe ".find_or_create" do
    let(:course) { create :course }
    let(:student) { create(:course_membership, :student, course: course).user }
    let(:assignment) { create :assignment, course: course }

    it "finds and existing grade for assignment and student" do
      grade = create :grade, assignment: assignment, student: student
      results = Grade.find_or_create(assignment.id,student.id)
      expect(results).to eq grade
    end

    it "creates a grade for assignment and student if none exists" do
      expect{Grade.find_or_create(assignment.id,student.id)}.to \
        change{ Grade.count }.by(1)
    end
  end

  describe ".find_or_create_grades" do
    let(:course) { create :course }
    let(:group) { create(:group, course: course) }
    let(:assignment) { create :assignment, course: course }
    let(:ids) { group.students.pluck(:id) }

    it "finds and existing grade for assignment and student" do
      results = Grade.find_or_create_grades(assignment.id, ids)
      expect(results.count).to eq ids.length
    end

    it "creates a grade for assignment and student if none exists" do
      expect { Grade.find_or_create_grades(assignment.id, ids) }.to \
        change{ Grade.count }.by(ids.length)
    end
  end

  describe "when it is saved" do
    let(:course) { create :course }
    let(:assignment) { create :assignment, course: course }
    let(:grade) { create :grade, assignment: assignment }

    it "updates earned badge visibility" do
      earned_badge = create(:earned_badge, student: grade.student, grade: grade, student_visible: false)
      grade.status = "Graded"
      grade.save
      expect(earned_badge.reload.student_visible).to be_truthy
    end
  end
end
