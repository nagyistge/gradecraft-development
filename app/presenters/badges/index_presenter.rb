require "./lib/showtime"

class Badges::IndexPresenter < Showtime::Presenter
  include Showtime::ViewContext

  def badges
    properties[:badges]
  end

  def accepted_badges
    properties[:accepted_badges]
  end

  def rejected_badges
    properties[:rejected_badges]
  end

  def proposed_badges
    properties[:proposed_badges]
  end

  def student
    properties[:student]
  end

  def earned_badges_count(badge)
    if student
      student.earned_badges_for_badge(badge)
    else
      badge.earned_count
    end
  end
end
