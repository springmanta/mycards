module ApplicationHelper
  def show_navbar_search?
    case controller_name
    when "home", "sessions", "registrations", "passwords"
      false
    else
      true
    end
  end

  def condition_badge(condition)
    colors = {
      "mint" => "bg-green-500",
      "near_mint" => "bg-green-400",
      "excellent" => "bg-blue-400",
      "good" => "bg-yellow-400",
      "lightly_played" => "bg-orange-400",
      "played" => "bg-orange-500",
      "poor" => "bg-red-500"
    }

    color = colors[condition] || "bg-gray-400"

    content_tag(:span, condition.titleize,
      class: "inline-block px-2 py-1 rounded text-xs font-semibold text-white #{color}")
  end
end
