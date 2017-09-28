class BadgesController < ApplicationController

  before_action :ensure_not_observer?, except: [:index, :show]
  before_action :ensure_staff?, except: [:index, :show, :propose, :new]
  before_action :find_badge, only: [:show, :edit, :destroy]
  before_action :use_current_course, only: [:index, :show, :new, :propose, :edit]

  # GET /badges
  def index
    render Badges::IndexPresenter.build({
      title: term_for(:badges),
      badges: @course.badges.ordered,
      student: current_student
    })
  end

  # GET /badges/:id
  def show
    render Badges::ShowPresenter.build({
      course: @course,
      badge: @badge,
      student: current_student,
      teams: @course.teams,
      params: params
    })
  end

  def new
    @badge = @course.badges.new
  end

  def edit
    @badge = Badge.find(params[:id])
  end

  def destroy
    @name = @badge.name
    @badge.destroy
    redirect_to badges_path,
      notice: "#{@name} #{term_for :badge} successfully deleted"
  end

  def update_proposal
    @badge = Badge.find(params[:id])
    update_value = params[:update_value]
    if @badge.update_attribute(:state, update_value)
      redirect_to badges_path, notice: "#{@badge.name} #{update_value.capitalize}"
    else
      redirect_to badges_path, notice: "#{@badge.name} Something Went Wrong"
    end
  end

  def export_structure
    course = current_user.courses.find_by(id: params[:id])
    respond_to do |format|
      format.csv { send_data BadgeExporter.new.export(course), filename: "#{ course.name } #{ (term_for :badges).titleize } - #{ Date.today }.csv" }
    end
  end

  private

  def find_badge
    @badge = current_course.badges.find(params[:id])
  end
end
