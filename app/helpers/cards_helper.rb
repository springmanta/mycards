module CardsHelper
  def color_name(code)
    {
      "W" => "White",
      "U" => "Blue",
      "B" => "Black",
      "R" => "Red",
      "G" => "Green"
    }[code] || code
  end
end
