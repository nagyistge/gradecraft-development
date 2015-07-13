# encoding: utf-8
require 'spec_helper'

describe "students/predictor/_badges" do

  before(:each) do
    clean_models
    @course = create(:course)
    badge = create(:badge, course: @course)
    student = create(:user)
    student.courses << @course
    view.stub(:current_course).and_return(@course)
    view.stub(:current_student).and_return(student)
    view.stub(:term_for).and_return("badges")
  end

  describe "with valuable badges" do
    it "renders successfully" do
      @course.valuable_badges?.should be_true
      render
    end
  end
end