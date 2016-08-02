require_relative "../services/imports_lms_assignments"

class ImportersController < ApplicationController
  before_filter :ensure_staff?
  before_filter :require_authentication, except: :index

  # GET /importers
  def index
  end

  # GET /importers/:importer_id/courses
  def courses
    @provider = params[:importer_id]
    @courses = syllabus.courses
  end

  # GET /importers/:importer_id/courses/:id/assignments
  def assignments
    @provider = params[:importer_id]
    @course = syllabus.course(params[:id])
    @assignments = syllabus.assignments(params[:id])
    @assignment_types = current_course.assignment_types
  end

  # POST /importers/:importer_id/courses/:id/assignments
  def assignments_import
    @provider = params[:importer_id]

    @result = Services::ImportsLMSAssignments.import @provider,
      ENV["#{@provider.upcase}_ACCESS_TOKEN"], params[:id], params[:assignment_ids],
      current_course, params[:assignment_type_id]

    if @result.success?
      render :assignments_import_results
    else
      @course = syllabus.course(params[:id])
      @assignments = syllabus.assignments(params[:id])
      @assignment_types = current_course.assignment_types

      render :assignments, alert: @result.message
    end
  end

  private

  def require_authentication
    provider = params[:importer_id]
    require_authentication_with provider
  end

  def require_authentication_with(provider)
    authorization = UserAuthorization.for(current_user, provider)
    return redirect_to "/auth/#{provider}" if authorization.nil?
  end

  def syllabus
    @syllabus ||= ActiveLMS::Syllabus.new(@provider,
                                          ENV["#{@provider.upcase}_ACCESS_TOKEN"])
  end
end
