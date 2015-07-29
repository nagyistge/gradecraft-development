#spec/controllers/assignment_type_weights_controller_spec.rb
require 'spec_helper'

describe AssignmentTypeWeightsController do

	context "as professor" do 
		
    before do
      @course = create(:course)
      @professor = create(:user)
      @professor.courses << @course
      @membership = CourseMembership.where(user: @professor, course: @course).first.update(role: "professor")
      @challenge = create(:challenge, course: @course)
      @course.challenges << @challenge
      @challenges = @course.challenges
      @student = create(:user)
      @student.courses << @course
      @team = create(:team, course: @course)
      @team.students << @student
      @teams = @course.teams

      login_user(@professor)
      session[:course_id] = @course.id
      allow(EventLogger).to receive(:perform_async).and_return(true)
    end

		describe "GET mass_edit" do  
      pending
    end

		describe "POST mass_update" do  
      pending
    end

	end

	context "as student" do 
    
    before do
      @course = create(:course)
      @challenge = create(:challenge, course: @course)
      @course.challenges << @challenge
      @challenges = @course.challenges
      @student = create(:user)
      @student.courses << @course
      @team = create(:team, course: @course)
      @team.students << @student
      @teams = @course.teams
      @challenge_grade = create(:challenge_grade, team: @team, challenge: @challenge)

      login_user(@student)
      session[:course_id] = @course.id
      allow(EventLogger).to receive(:perform_async).and_return(true)
    end

		describe "GET mass_edit" do  
      pending
    end

		describe "POST mass_update" do  
      pending
    end
    
	end

end