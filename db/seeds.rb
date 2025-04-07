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
  photo_url: "https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcQ0OWShaP-sYORlvGQeteuYcDZUi3yuZe66oA&s"
)
force_of_will.save
puts "Successfully created #{force_of_will.name}\n"

thrasios = Card.new(
  colors: "Blue Green",
  convertedManaCost: 2,
  name: "Thrasios, Triton Hero",
  card_type: "Creature",
  photo_url: "https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcQTcON8ES6FLAnX08GrbV5AcHrwVWbpmU5j-g&s"
)
thrasios.save
puts "Successfully created #{thrasios.name}\n"

neoform = Card.new(
  colors: "Blue Green",
  convertedManaCost: 2,
  name: "Neoform",
  card_type: "Sorcery",
  photo_url: "https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcQptzex_D-oRCyWL0mt1ktIwc96I0ErxySklQ&s"
)
neoform.save
puts "Successfully created #{neoform.name}\n"

swords = Card.new(
  colors: "White",
  convertedManaCost: 1,
  name: "Swords to Plowshares",
  card_type: "Instant",
  photo_url: "https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcQ8UTc71qvpSAe03BpRT36rh0JVcItPqMwTWA&s"
)
swords.save
puts "Successfully created #{swords.name}\n"

rhystic = Card.new(
  colors: "Blue",
  convertedManaCost: 3,
  name: "Rhystic Study",
  card_type: "Enchantment",
  photo_url: "https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcRyCl_fb8hA81X7_afoTax-4bMJvurVeqOvBw&s"
)
rhystic.save
puts "Successfully created #{rhystic.name}\n"

mox = Card.new(
  colors: "Colorless",
  convertedManaCost: 0,
  name: "Mox Diamond",
  card_type: "Artifact",
  photo_url: "https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcT3lur86arcGYpfGO9YqlZsMMWYwmejw_LLdA&s"
)
mox.save
puts "Successfully created #{mox.name}\n"

ring = Card.new(
  colors: "Colorless",
  convertedManaCost: 4,
  name: "The One Ring",
  card_type: "Artifact",
  photo_url: "https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcQ3QfspiMij7_KHXqpoUZzP2j_dGGvAR8PKJA&s"
)
ring.save
puts "Successfully created #{ring.name}\n"

puts "Successfully created #{Card.count} cards"
puts "Seeding ended."
