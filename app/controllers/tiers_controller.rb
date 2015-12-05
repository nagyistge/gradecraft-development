class TiersController < ApplicationController
  before_filter :ensure_staff?

  before_action :find_tier, except: [:create]

  respond_to :html, :json

  def create
    @tier = Tier.create params[:tier]
    respond_with @tier, layout: false
  end

  def destroy
    @tier.destroy
    render :nothing => true
  end
  
  def update
    @tier.update_attributes params[:tier]
    respond_with @tier, layout: false
  end

  private
  def find_tier
    @tier = Tier.find params[:id]
  end
end
