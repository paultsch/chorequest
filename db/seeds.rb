# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).
#
# Example:
#
#   ["Action", "Comedy", "Drama", "Horror"].each do |genre_name|
#     MovieGenre.find_or_create_by!(name: genre_name)
#   end

parent1 = Parent.find_or_create_by!(email: 'alice@example.com') do |p|
  p.name = 'Alice Parent'
  p.password = 'password'
end
parent2 = Parent.find_or_create_by!(email: 'bob@example.com') do |p|
  p.name = 'Bob Parent'
  p.password = 'password'
end

child1 = parent1.children.find_or_create_by!(name: 'Sam') do |c|
  c.birthday = 8.years.ago
  c.pin_code = '1234'
end
child2 = parent1.children.find_or_create_by!(name: 'Lily') do |c|
  c.birthday = 6.years.ago
  c.pin_code = '2345'
end
child3 = parent2.children.find_or_create_by!(name: 'Max') do |c|
  c.birthday = 10.years.ago
  c.pin_code = '3456'
end

chores = [
	{ name: 'Make Bed', description: 'Tidy your bed', definition_of_done: 'Sheets straight, pillows fluffed', token_amount: 5 },
	{ name: 'Brush Teeth', description: 'Brush for 2 minutes', definition_of_done: 'Teeth brushed', token_amount: 2 },
	{ name: 'Set Table', description: 'Put plates and cutlery', definition_of_done: 'Table set', token_amount: 3 },
	{ name: 'Homework', description: 'Complete homework', definition_of_done: 'Homework finished', token_amount: 10 },
	{ name: 'Tidy Toys', description: 'Put toys away', definition_of_done: 'Toy box tidy', token_amount: 4 }
]

chores.each { |c| Chore.find_or_create_by!(name: c[:name]) { |r| r.assign_attributes(c) } }

game = Game.find_or_create_by!(name: 'Pong') do |g|
  g.description = 'Classic pong game'
  g.token_per_minute = 1
end

# Give kids some tokens if they have none yet
TokenTransaction.find_or_create_by!(child: child1, description: 'Initial grant') { |t| t.amount = 20 }
TokenTransaction.find_or_create_by!(child: child2, description: 'Initial grant') { |t| t.amount = 15 }
TokenTransaction.find_or_create_by!(child: child3, description: 'Initial grant') { |t| t.amount = 10 }

# Create a default super-admin if Admins table exists
begin
  if ActiveRecord::Base.connection.table_exists?('admins')
    email = ENV.fetch('SUPER_ADMIN_EMAIL', 'superadmin@example.com')
    pw = ENV.fetch('SUPER_ADMIN_PASSWORD', 'password')
    AdminUser.find_or_create_by!(email: email) do |a|
      a.password = pw
      a.password_confirmation = pw
      a.name = 'Super Admin'
    end
  end
rescue => e
  Rails.logger.warn "Skipping super-admin seed: #{e.message}"
end
