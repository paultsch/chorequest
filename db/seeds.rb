# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).
#
# Example:
#
#   ["Action", "Comedy", "Drama", "Horror"].each do |genre_name|
#     MovieGenre.find_or_create_by!(name: genre_name)
#   end

Parent.destroy_all
Child.destroy_all
Chore.destroy_all
ChoreAssignment.destroy_all
TokenTransaction.destroy_all
Game.destroy_all
GameSession.destroy_all

parent1 = Parent.create!(name: 'Alice Parent', email: 'alice@example.com', password: 'password')
parent2 = Parent.create!(name: 'Bob Parent', email: 'bob@example.com', password: 'password')

child1 = parent1.children.create!(name: 'Sam', age: 8, pin_code: '1234')
child2 = parent1.children.create!(name: 'Lily', age: 6, pin_code: '2345')
child3 = parent2.children.create!(name: 'Max', age: 10, pin_code: '3456')

chores = [
	{ name: 'Make Bed', description: 'Tidy your bed', definition_of_done: 'Sheets straight, pillows fluffed', token_amount: 5 },
	{ name: 'Brush Teeth', description: 'Brush for 2 minutes', definition_of_done: 'Teeth brushed', token_amount: 2 },
	{ name: 'Set Table', description: 'Put plates and cutlery', definition_of_done: 'Table set', token_amount: 3 },
	{ name: 'Homework', description: 'Complete homework', definition_of_done: 'Homework finished', token_amount: 10 },
	{ name: 'Tidy Toys', description: 'Put toys away', definition_of_done: 'Toy box tidy', token_amount: 4 }
]

chores.each { |c| Chore.create!(c) }

game = Game.create!(name: 'Pong', description: 'Classic pong game', token_per_minute: 1)

# A sample transaction to give kids some tokens
TokenTransaction.create!(child: child1, amount: 20, description: 'Initial grant')
TokenTransaction.create!(child: child2, amount: 15, description: 'Initial grant')
TokenTransaction.create!(child: child3, amount: 10, description: 'Initial grant')

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
