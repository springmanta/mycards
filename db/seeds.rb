# This file should ensure the existence of record required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).
#
# Example:
#
#   ["Action", "Comedy", "Drama", "Horror"].each do |genre_name|
#     MovieGenre.find_or_create_by!(name: genre_name)
#   end

puts "Seed starting"
User.destroy_all
Card.destroy_all

user1 = User.new(email_address: "simaopmartins@gmail.com", password: "Thrasios_2016")
user1.save!
puts "user Simão created"

card1 = Card.new(
  name: "Thrasios, Triton Hero",
  set_name: "Commander 2016",
  rarity: "rare",
  mana_cost: "{G}{U}",
  type_line: "Legendary Creature — Merfolk Wizard",
  oracle_text: "{4}: Scry 1, then reveal the top card of your library. If it's a land card, put it onto the battlefield tapped. Otherwise, draw a card.\nPartner (You can have two commanders if both have partner.)",  # \n for line break
  power: "1",
  toughness: "3",
  image_url: "https://cards.scryfall.io/large/front/2/1/21e27b91-c7f1-4709-aa0d-8b5d81b22a0a.jpg?1721690845"
)

card1.save!
puts "#{card1.name} successfully created."

card2 = Card.new(
  name: "Krark, the Thumbless",
  set_name: "Commander Legends",
  rarity: "rare",
  mana_cost: "0{R}",
  type_line: "Legendary Creature — Goblin Wizard",
  oracle_text: "{Whenever you cast an instant or sorcery spell, flip a coin. If you lose the flip, return that spell to its owner’s hand. If you win the flip, copy that spell, and you may choose new targets for the copy.
Partner (You can have two commanders if both have partner.)",  # \n for line break
  power: "2",
  toughness: "2",
  image_url: "https://cards.scryfall.io/large/front/0/6/06a981cd-1951-438e-95c9-68294795638e.jpg?1617148336"
)

card2.save!
puts "#{card2.name} successfully created."

puts "<-- Seeds ending... -->"
