module ApplicationHelper
  def show_navbar_search?
    case controller_name
    when "home", "sessions", "registrations", "passwords"
      false
    else
      true
    end
  end
end
