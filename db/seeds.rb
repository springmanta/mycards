# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).
#
# Example:
#
#   ["Action", "Comedy", "Drama", "Horror"].each do |genre_name|
#     MovieGenre.find_or_create_by!(name: genre_name)
#   end

puts "Initializing Seeds"
puts "Deleting all data"
Card.destroy_all
puts "Creating new cards"

force_of_will = Card.new(
  colors: "Blue",
  convertedManaCost: 5,
  name: "Force of Will",
  card_type: "Instant",
  photo_url: "https://gatherer.wizards.com/Handlers/Image.ashx?multiverseid=3107&type=card"
)
force_of_will.save
puts "Successfully created #{force_of_will.name}\n"

thrasios = Card.new(
  colors: "Blue Green",
  convertedManaCost: 2,
  name: "Thrasios, Triton Hero",
  card_type: "Creature",
  photo_url: "https://gatherer.wizards.com/Handlers/Image.ashx?multiverseid=420663&type=card"
)
thrasios.save
puts "Successfully created #{thrasios.name}\n"

swords = Card.new(
  colors: "White",
  convertedManaCost: 1,
  name: "Swords to Plowshares",
  card_type: "Instant",
  photo_url: "https://gatherer.wizards.com/Handlers/Image.ashx?multiverseid=1367&type=card"
)
swords.save
puts "Successfully created #{swords.name}\n"

rhystic = Card.new(
  colors: "Blue",
  convertedManaCost: 3,
  name: "Rhystic Study",
  card_type: "Enchantment",
  photo_url: "https://gatherer.wizards.com/Handlers/Image.ashx?multiverseid=24589&type=card"
)
rhystic.save
puts "Successfully created #{rhystic.name}\n"


puts "Successfully created #{Card.count} cards"
puts "Seeding ended."
