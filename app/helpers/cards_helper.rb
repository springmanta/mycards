module CardsHelper
  def color_name(code)
    {
      "W" => "White",
      "U" => "Blue",
      "B" => "Black",
      "R" => "Red",
      "G" => "Green",
      "[]" => "Colorless"
    }[code] || code
  end
end
