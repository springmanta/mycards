# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).
#
# Example:
#
#   ["Action", "Comedy", "Drama", "Horror"].each do |genre_name|
#     MovieGenre.find_or_create_by!(name: genre_name)
#   end

puts "Seed starting"
Card.destroy_all

card = Card.new(
  name: "Thrasios, Triton Hero",
  set_name: "Commander 2016",
  rarity: "rare",
  mana_cost: "{G}{U}",
  type_line: "Legendary Creature — Merfolk Wizard",
  oracle_text: "{4}: Scry 1, then reveal the top card of your library. If it's a land card, put it onto the battlefield tapped. Otherwise, draw a card.\nPartner (You can have two commanders if both have partner.)",  # \n for line break
  power: "1",
  toughness: "2",
  image_url: "https://cards.scryfall.io/large/front/2/1/21e27b91-c7f1-4709-aa0d-8b5d81b22a0a.jpg?1721690845"
)

card.save!
puts "#{card.name} successfully created."
