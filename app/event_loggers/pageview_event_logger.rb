class PageviewEventLogger < ApplicationEventLogger
  include EventLogger::Enqueue

  # queue to use for login event jobs
  @queue = :pageview_event_logger
  @event_name = "Pageview"

  # instance methods
  def event_type
    "pageview"
  end

  def event_attrs
    @event_attrs ||= base_attrs.merge(page: event_session[:request].try(:original_fullpath))
  end
end
