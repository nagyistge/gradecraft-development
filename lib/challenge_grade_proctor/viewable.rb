# Determines if a `ChallengeGrade` resource can be viewed by a user. If no user is
# supplied in the options, it will default to the Grade's student.
#
# Options include:
#   course:  Will verify the challenge grade is for the course
#   user:    Determines permissions for supplied user rather than the
#            challenge grade's student
#
class ChallengeGradeProctor
  module Viewable
    include Base

    def viewable?(options={})
      return false if challenge_grade.nil?

      user = options[:user]
      course = options[:course] || challenge_grade.course

      challenge_grade_for_course?(course) &&
        user.is_staff?(course) || challenge_grade_visible_by_students?
    end

    private

    # Challenge grades for the course are visible to all students, as long as
    # they're released
    def challenge_grade_visible_by_students?
      challenge_grade.is_released? ||
        (challenge_grade.is_graded? && !challenge_grade.challenge.release_necessary?)
    end
  end
end
