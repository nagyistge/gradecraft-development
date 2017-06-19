class SamlController < ApplicationController
  skip_before_action :require_login, except: [:logout]
  skip_before_action :require_course_membership, except: :logout
  protect_from_forgery except: :consume

  def init
    request = OneLogin::RubySaml::Authrequest.new
    redirect_to(request.create(SAML_SETTINGS))
  end

  def consume
    response = OneLogin::RubySaml::Response.new(params[:SAMLResponse],
      settings: SAML_SETTINGS)

    if response.success?
      email = response.attributes["urn:oid:0.9.2342.19200300.100.1.3"]
      @user = User.find_by_email(email)
      if !@user.blank?
        auto_login @user
        session[:course_id] = CourseRouter.current_course_for @user
        redirect_back_or_to dashboard_path
      else
        # This needs to be updated to create a new course and log the user in to it
        redirect_to um_info_path
      end
    else
      redirect_to root_url, notice: "authentication error"
    end
  end

  def metadata
    meta = OneLogin::RubySaml::Metadata.new
    render xml: meta.generate(SAML_SETTINGS, true)
  end

  def logout
    redirect_to logout_url
  end
end
