describe User do
  let(:course) { build(:course) }
  let(:student) { create(:user, username: "simple", last_name: "Oneofakind") }
  let(:assignment) { create(:assignment, course: course) }
  let(:grade) { create(:grade, assignment: assignment, student:student) }
  let(:badge) { create(:badge, course: course, can_earn_multiple_times: true) }
  let(:single_badge) { create(:badge, course: course, can_earn_multiple_times: false) }

  let!(:course_membership) { create(:course_membership, user: student, course: course, role: "student", score: 100000, character_profile: "The six-fingered man.") }

  describe "validations" do
    it "requires the password confirmation to match" do
      user = User.new password: "test", password_confirmation: "blah"
      expect(user).to_not be_valid
      expect(user.errors[:password_confirmation]).to include "doesn't match Password"
    end

    it "requires that there is a password confirmation" do
      student.password = "test"
      expect(student).to_not be_valid
      expect(student.errors[:password_confirmation]).to include "can't be blank"
    end
  end

  describe "order_by_name" do
    it "should return users alphabetical by last name" do
      User.destroy_all
      student = create(:user, last_name: "Alpha")
      student_2 = create(:user, last_name: "Zed")
      expect(User.all.order_by_name).to eq([student, student_2])
    end
  end

  describe ".find_by_insensitive_email" do
    it "should return the user no matter what the case the email address is in" do
      expect(described_class.find_by_insensitive_email(student.email.upcase)).to eq student
    end

    it "returns nil if the specified email is nil" do
      expect(described_class.find_by_insensitive_email(nil)).to be_nil
    end
  end

  describe ".find_by_insensitive_username" do
    it "should return the user no matter what the case the username is in" do
      expect(User.find_by_insensitive_username(student.username.upcase)).to eq student
    end

    it "returns nil if the specified username is nil" do
      expect(described_class.find_by_insensitive_username(nil)).to be_nil
    end
  end

  describe ".find_by_insensitive_last_name" do
    it "should return the user no matter what the case the last name is in" do
      expect(User.find_by_insensitive_last_name(student.last_name.upcase)).to eq [student]
    end

    it "returns nil if the specified last name is nil" do
      expect(described_class.find_by_insensitive_last_name(nil)).to be_empty
    end
  end

  describe ".find_by_insensitive_first_name" do
    it "should return the user no matter what the case the first name is in" do
      expect(User.find_by_insensitive_first_name(student.first_name.upcase)).to eq [student]
    end

    it "returns nil if the specified first name is nil" do
      expect(described_class.find_by_insensitive_first_name(nil)).to be_empty
    end
  end

  describe ".find_by_insensitive_full_name" do
    it "should return the user no matter what the case the name parts are in" do
      expect(User.find_by_insensitive_full_name(student.first_name.upcase, student.last_name.upcase)).to eq [student]
    end

    it "returns nil if the specified name parts are nil" do
      expect(described_class.find_by_insensitive_full_name(nil, nil)).to be_empty
    end
  end

  describe ".email_exists?" do
    it "should return true if the email already exists" do
      expect(User.email_exists?(student.email.upcase)).to eq true
    end

    it "should return false if the email does not exist" do
      expect(User.email_exists?("blah@somewhere-cool.biz")).to eq false
    end
  end

  describe "#onboarded?" do
    it "responds with the onboarding state for student and course" do
      expect(student.onboarded?(course)).to eq(false)
      CourseMembership.where(user: student, course: course).first.update(has_seen_course_onboarding: true)
      expect(student.onboarded?(course)).to eq(true)
    end
  end

  describe "submitter directory names" do
    describe "#submitter_directory_name" do
      it "formats the submitter info into an alphabetical submitter directory name" do
        expect(student.submitter_directory_name).to eq("#{ student.last_name }, #{ student.first_name }")
      end
    end

    describe "#submitter_directory_name_with_suffix" do
      it "formats the submitter directory name with suffix" do
        expect(student.submitter_directory_name_with_suffix).to eq("#{ student.last_name }, #{ student.first_name } - simple")
      end
    end
  end

  describe "#time_zone" do
    it "defaults to Eastern Time" do
      expect(subject.time_zone).to eq("Eastern Time (US & Canada)")
    end
  end

  describe "#same_name_as?" do
    let(:ben_bailey1) { create(:user, first_name: "Ben", last_name: "Bailey") }
    let(:ben_bailey2) { create(:user, first_name: "Ben", last_name: "Bailey") }
    let(:roger_daltry) { create(:user, first_name: "Roger", last_name: "Daltry") }

    context "has the same name as the user given" do
      it "returns true" do
        expect(ben_bailey1.same_name_as?(ben_bailey2)).to be_truthy
      end
    end

    context "has a different name than the user given" do
      it "returns false" do
        expect(ben_bailey1.same_name_as?(roger_daltry)).to be_falsey
      end
    end
  end

  describe ".students_for_course" do
    it "returns all the students for a course" do
      auditor = create(:course_membership, course: course, role: "student", auditing: true).user
      expect(User.students_for_course(course).count).to eq(2)
      expect(User.students_for_course(course).pluck(:id)).to include(student.id, auditor.id)
    end
  end

  describe ".students_being_graded_for_course" do
    it "returns all the students that are being graded" do
      expect(User.students_being_graded_for_course(course).pluck(:id)).to include(student.id)
    end
  end

  describe "#activated?" do
    it "is activated when the activation state is active" do
      user = build :user, activation_state: "active"
      expect(user).to be_activated
    end

    it "is not activated when the activation state is pending" do
      user = build :user, activation_state: "pending"
      expect(user).to_not be_activated
    end
  end

  describe "#name" do
    it "returns the student's full name if present" do
      expect(student.name).to eq("#{ student.first_name } #{ student.last_name }")
    end

    it "returns the User ID if not" do
      student.last_name = nil
      student.first_name = nil
      expect(student.name).to eq("User #{student.id}")
    end
  end

  describe "#self_reported_done?" do
    it "is not self reported if there are no grades" do
      expect(student).to_not be_self_reported_done(assignment)
    end

    it "is self reported if there is at least one graded grade" do
      grade.update_attribute :student_visible, true
      expect(student).to be_self_reported_done(assignment)
    end
  end

  describe "#role" do
    it "returns the first role found from the course membership" do
      expect(student.role(course)).to eq "student"
    end

    it "returns nil if the course membership is not found" do
      expect(student.role(Course.new)).to eq nil
    end

    it "returns admin if the user is an admin" do
      student.admin = true
      student.save
      expect(student.role(course)).to eq "admin"
    end
  end

  describe "#is_staff?(course)" do
    let(:user) { create :user }

    it "returns true if the user is a professor in the course" do
      create(:course_membership, :professor, course: course, user: user)
      expect(user.is_staff?(course)).to eq(true)
    end

    it "returns true if the user is a GSI in the course" do
      create(:course_membership, :staff, course: course, user: user)
      expect(user.is_staff?(course)).to eq(true)
    end

    it "returns true if the user is an admin in the course" do
      create(:course_membership, :admin, course: course, user: user)
      expect(user.is_staff?(course)).to eq(true)
    end

    it "returns false if the user is a student in the course" do
      create(:course_membership, :student, course: course, user: user)
      expect(user.is_staff?(course)).to eq(false)
    end

    it "requires an email to end with umich if an internal user" do
      student.internal = true
      student.email = "blah@example.com"
      expect(student).to_not be_valid
      expect(student.errors[:email]).to include "must be a University of Michigan email"
    end

    it "requires an email to end with umich if it was saved with a umich email" do
      student.email = "blah@umich.edu"
      student.save
      student.email = "blah@example.com"
      expect(student).to_not be_valid
      expect(student.errors[:email]).to include "must be a University of Michigan email"
    end
  end

  describe "#character_profile(course)" do
    it "returns the student's character profile if it's present" do
      expect(student.character_profile(course)).to eq("The six-fingered man.")
    end
  end

  describe "#archived_courses" do
    it "returns all archived courses for a student" do
      course_2 = create(:course, status: false)
      create(:course_membership, :student, course: course_2, user: student)
      expect(student.archived_courses).to eq([course_2])
    end
  end

  describe "#grade_released_for_assignment?(assignment)" do
    it "returns false if the grade is not student visible" do
      expect(student.grade_visible_for_assignment?(assignment)).to eq(false)
    end

    it "returns true if the grade is graded" do
      grade.student_visible = true
      grade.save!
      expect(student.grade_visible_for_assignment?(assignment)).to eq(true)
    end

    it "returns true if the grade is released" do
      assignment.save
      grade.student_visible = true
      grade.save!
      expect(student.grade_visible_for_assignment?(assignment)).to eq(true)
    end
  end

  describe "#grades_for_course(course)" do
    it "returns the student's grades for a course" do
      grade_1 = create(:student_visible_grade, raw_points: 100, student: student, course: course)
      grade_2 = create(:student_visible_grade, raw_points: 300, student: student, course: course)
      expect(student.grades_for_course(course)).to include(grade_1, grade_2)
    end
  end

  describe "#grade_for_assignment(assignment)" do
    it "returns the grade for an assignment if it exists" do
      grade = create(:grade, assignment: assignment, student: student)
      expect(student.grade_for_assignment(assignment)).to eq(grade)
    end
  end

  describe "#grade_for_assignment_id(assignment_id)" do
    it "returns the grade for an assignment of a particular id if it exists" do
      grade = create(:grade, assignment: assignment, student: student)
      expect(student.grade_for_assignment_id(assignment.id)).to eq([grade])
    end
  end

  describe "#predictions_for_course?(course)" do
    it "returns true if the student has predicted any assignment" do
      prediction = create(:predicted_earned_grade, student: student, assignment: assignment)
      expect(student.predictions_for_course?(course)).to eq true
    end

    it "returns false if the student has not predicted any assignments" do
      expect(student.predictions_for_course?(course)).to eq false
    end
  end

  describe "#last_course_login(course)" do
    it "returns nil  if the student has not logged into the course site" do
      expect(student.last_course_login(course)).to be nil
    end

    it "returns the last time the student logged into the course" do
      login_time = DateTime.now
      student_2 = create(:user)
      create(:course_membership, :student, user: student_2, course: course, last_login_at:
      login_time)
      expect(student_2.last_course_login(course).to_i).to eq (login_time.to_i)
    end
  end

  describe "#submission_for_assignment(assignment)" do
    context "with a non-group assignment" do
      context "when there is not a draft submission" do
        let!(:submitted_submission) { create(:submission, assignment: assignment, student: student) }

        it "returns the submission for an assignment" do
          expect(student.submission_for_assignment(assignment)).to eq(submitted_submission)
        end
      end

      context "when there is a draft submission" do
        let!(:draft_submission) { create(:draft_submission, assignment: assignment, student: student) }

        it "returns nil if submitted_only is true" do
          expect(student.submission_for_assignment(assignment)).to be_nil
        end

        it "returns the draft submission if submitted_only is false" do
          expect(student.submission_for_assignment(assignment, false)).to eq(draft_submission)
        end
      end
    end

    context "with a group assignment" do
      let(:assignment) { create(:group_assignment) }
      let(:group) { create(:group) }

      before(:each) do
        create(:assignment_group, group: group, assignment: assignment)
        create(:group_membership, student: student, group: group)
      end

      context "when the submission is not a draft submission" do
        let!(:submitted_submission) { create(:group_submission, assignment: assignment, group: group) }

        it "returns the group submission"  do
          expect(student.submission_for_assignment(assignment)).to eq(submitted_submission)
        end
      end

      context "when the submission is a draft submission" do
        let!(:draft_submission) { create(:group_submission, assignment: assignment, group: group, submitted_at: nil) }

        it "returns nil if submitted_only is true" do
          expect(student.submission_for_assignment(assignment)).to be_nil
        end

        it "returns the draft submission if submitted_only is false" do
          expect(student.submission_for_assignment(assignment, false)).to eq(draft_submission)
        end
      end
    end
  end

  describe "#earned_badges_for_course(course)", :unreliable do
    let(:student) { create :user, courses: [course], role: :student }

    it "returns the students' earned_badges for a course" do
      earned_badge_1 = create(:earned_badge, student: student, course: course)
      earned_badge_2 = create(:earned_badge, student: student, course: course)
      expect(student.earned_badges_for_course(course)).to eq([earned_badge_1, earned_badge_2])
    end
  end

  describe "#awarded_badges_for_badge(badge)" do
    it "returns the students' earned_badges for a particular badge" do
      earned_badge_1 = create(:earned_badge, badge: badge, student: student, course: course)
      expect(student.awarded_badges_for_badge(badge)).to eq([earned_badge_1])
    end
  end

  describe "#awarded_badges_for_badge_count(badge)" do
    it "returns the students' earned_badges for a course" do
      earned_badge_1 = create(:earned_badge, badge: badge, student: student, course: course)
      earned_badge_2 = create(:earned_badge, badge: badge, student: student, course: course)
      expect(student.awarded_badges_for_badge_count(badge)).to eq(2)
    end
  end

  describe "#weight_for_assignment_type(assignment_type)" do
    it "should return a student's assigned weight for an assignment type" do
      assignment_type = create(:assignment_type, course: course)
      assignment = create(:assignment, assignment_type: assignment_type, course: course)
      create(:assignment_type_weight, student: student, course: course, assignment_type: assignment_type, weight: 3)
      expect(student.weight_for_assignment_type(assignment_type)).to eq(3)
    end
  end

  describe "#weight_spent?(course)" do
    it "should return the summed weight count for a course, for a student" do
      course.total_weights = 6
      course.max_weights_per_assignment_type = 4
      course.max_assignment_types_weighted = 3
      assignment_type = create(:assignment_type, course: course, student_weightable: true)
      assignment_type_2 = create(:assignment_type, course: course, student_weightable: true)
      assignment = create(:assignment, course: course, assignment_type: assignment_type)
      assignment_2 = create(:assignment, course: course, assignment_type: assignment_type_2)
      create(:assignment_type_weight, student: student, course: course, assignment_type: assignment_type, weight: 4)
      create(:assignment_type_weight, student: student, course: course, assignment_type: assignment_type_2, weight: 2)
      expect(student.weight_spent?(course)).to eq(true)
    end
  end

  describe "#total_weight_spent(course)" do
    it "should return the summed weight count for a course, for a student" do
      course.total_weights = 6
      course.max_weights_per_assignment_type = 4
      course.max_assignment_types_weighted = 3
      assignment_type = create(:assignment_type, course: course, student_weightable: true)
      assignment_type_2 = create(:assignment_type, course: course, student_weightable: true)
      assignment_type_3 = create(:assignment_type, course: course, student_weightable: true)
      assignment = create(:assignment, course: course, assignment_type: assignment_type)
      assignment_2 = create(:assignment, course: course, assignment_type: assignment_type_2)
      assignment_3 = create(:assignment, course: course, assignment_type: assignment_type_3)
      assignment_weight_1 = create(:assignment_type_weight, student: student, assignment_type: assignment_type, weight: 2)
      assignment_weight_2 = create(:assignment_type_weight, student: student, assignment_type: assignment_type_2, weight: 2)
      assignment_weight_3 = create(:assignment_type_weight, student: student, assignment_type: assignment_type_3, weight: 2)
      expect(student.total_weight_spent(course)).to eq(6)
    end
  end

  describe "#weighted_assignments?" do
    it "should return true if the student has weighted assignments" do
      create(:assignment_type_weight, student: student, course: course)
      expect(student.weighted_assignments?(course)).to eq(true)
    end

    it "should return false if the student has not weighted any assignments" do
      expect(student.weighted_assignments?(course)).to eq(false)
    end
  end

  context "when course has groups" do
    let!(:group) { create(:group, course: course) }

    describe "#group_for_assignment(assignment)" do
      it "returns a student's group for a particular assignment if present" do
        FactoryGirl.create(:assignment_group, group: group, assignment: assignment)
        FactoryGirl.create(:group_membership, student: student, group: group)
        expect(student.group_for_assignment(assignment)).to eq(group)
      end
    end

    describe "#has_group_for_assignment?" do
      it "returns false for individual assignments" do
        FactoryGirl.create(:assignment_group, group: group, assignment: assignment)
        FactoryGirl.create(:group_membership, student: student, group: group)
        assignment.update(grade_scope: "Individual")
        expect(student.has_group_for_assignment?(assignment)).to be_falsey
      end

      it "returns false if the student has no group membership" do
        assignment.update(grade_scope: "Group")
        expect(student.has_group_for_assignment?(assignment)).to be_falsey
      end

      it "returns true if the student is in a group" do
        assignment.update(grade_scope: "Group")
        FactoryGirl.create(:assignment_group, group: group, assignment: assignment)
        FactoryGirl.create(:group_membership, student: student, group: group)
        expect(student.has_group_for_assignment?(assignment)).to be_truthy
      end
    end
  end

  context "when the course has teams" do
    let(:team) { create(:team, course: course) }
    let(:student_in_team) { create :user, courses: [course], last_name: "Team", role: :student }

    before do
      team.students << student_in_team
    end

    describe ".students_for_course with a team" do
      it "returns only students in the team" do
        expect(User.students_for_course(course, team)).to eq [student_in_team]
      end
    end

    describe ".students_for_course with a team" do
      it "returns only students in the team" do
        expect(User.students_for_course(course, team)).to eq [student_in_team]
      end
    end

    describe ".students_being_graded_for_course with a team" do
      it "returns only students in the team that are being graded" do
        expect(User.students_being_graded_for_course(course, team)).to eq [student_in_team]
      end
    end

    describe "#team_for_course(course)" do
      it "returns the student's team for the course" do
        expect(student_in_team.team_for_course(course)).to eq(team)
      end

      it "returns nil if the student doesn't have a team" do
        expect(student.team_for_course(course)).to eq(nil)
      end
    end

    describe "#team_leaders(course)" do
      let(:team_leader) { create :user }

      it "returns the students team leaders if they're present" do
        create(:team_leadership, team: team, leader: team_leader)
        expect(student_in_team.team_leaders(course)).to eq([team_leader])

      end

      it "returns nil if there are no team leaders present" do
        expect(student_in_team.team_leaders(course)).to eq([])
      end
    end
  end

  context "student_visible_earned_badges" do
    it "should know which badges a student has earned" do
      earned_badges = create_list(:earned_badge, 3, course: course, student: student)
      expect(student.student_visible_earned_badges(course)).to eq(earned_badges)
    end

    it "should not select non-visible student badges" do
      earned_badges = create_list(:earned_badge, 3, course: course, student: student, grade: (create :in_progress_grade))
      expect(student.student_visible_earned_badges(course)).to be_empty
    end

    it "should not return unearned badges as earned badges" do
      unearned_badges = create_list(:badge, 2, course: course)
      visible_earned_badges = create_list(:earned_badge, 3, course: course, student: student)
      unique_earned_badges = student.student_visible_earned_badges(course)
      expect(unique_earned_badges).not_to include(*unearned_badges)
    end
  end

  context "unique_student_earned_badges" do
    it "should return a unique list of badges earned" do
      create_list(:earned_badge, 2, course: course, badge: badge, student: student)
      expect(student.unique_student_earned_badges(course)).to eq([badge])
    end

    it "should not return unearned badges" do
      badge_unearned = create(:badge, course: course)
      expect(student.unique_student_earned_badges(course)).not_to include(badge_unearned)
    end
  end

  context "student_visible_unearned_badges" do
    it "should know which badges a student has yet to earn" do
      badge = create(:badge, course: course, visible: true)
      expect(student.student_visible_unearned_badges(course)).to include(badge)
    end

    it "should not return earned badges as unearned ones" do
      earned_badge = create(:earned_badge, course: course, student: student)
      expect(student.student_visible_unearned_badges(course)).not_to include(earned_badge)
    end
  end

  context "instructor is editing the grade for a student's submission" do
    before(:each) do
      another_assignment = create(:assignment)
      another_grade = create(:grade, assignment: assignment)
    end

    it "should not see badges that aren't included in the current course" do
      bizarro_world = create(:course)
      bizarro_badge = create(:badge, course: bizarro_world)
      bizarro_grade = create(:grade, student: student, course: course)
      expect(student.earnable_course_badges_for_grade(grade)).not_to include(bizarro_badge)
    end

    it "should see badges for the current course" do
      EarnedBadge.destroy_all course_id: course[:id]
      expect(student.earnable_course_badges_for_grade(grade)).to include(badge, single_badge)
    end

    it "should show course badges that the student has yet to earn", broken: true do
      EarnedBadge.destroy_all course_id: course[:id]
      expect(student.earnable_course_badges_for_grade(grade)).to include(badge, single_badge)
    end
  end
end
