require "light-service"
require "active_record_spec_helper"
require "./app/services/cancels_course_membership/destroys_flagged_users"

describe Services::Actions::DestroysFlaggedUsers do
  let(:course) { membership.course }
  let(:membership) { create :course_membership, :student }
  let(:student) { membership.user }

  it "expects the membership to find the flagged users to destroy" do
    expect { described_class.execute }.to \
      raise_error LightService::ExpectedKeysNotInContextError
  end

  it "destroys the flagged users" do
    another_flagger = create(:course_membership, :professor)
    student.courses << another_flagger.course
    another_flagged_user = create :flagged_user, flagged: student,
      flagger: another_flagger.user, course: another_flagger.course
    flagger = create(:course_membership, :professor, course: course)
    course_flagged_user = create :flagged_user, flagged: student,
      course: course, flagger: flagger.user
    described_class.execute membership: membership
    expect(FlaggedUser.where(flagged_id: student.id)).to \
      eq [another_flagged_user]
  end
end
