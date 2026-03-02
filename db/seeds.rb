# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.

Parent.destroy_all
Child.destroy_all
Chore.destroy_all
ChoreAssignment.destroy_all
TokenTransaction.destroy_all
Game.destroy_all
GameSession.destroy_all

parent1 = Parent.create!(name: 'Alice Parent', email: 'alice@example.com', password: 'password')
parent2 = Parent.create!(name: 'Bob Parent', email: 'bob@example.com', password: 'password')

child1 = parent1.children.create!(name: 'Sam', birthday: 8.years.ago.to_date, pin_code: '1234')
child2 = parent1.children.create!(name: 'Lily', birthday: 6.years.ago.to_date, pin_code: '2345')
child3 = parent2.children.create!(name: 'Max', birthday: 10.years.ago.to_date, pin_code: '3456')

chore_templates = [
  { name: 'Make Bed', description: 'Tidy your bed each morning', definition_of_done: 'Sheets are straight, pillows are fluffed, and nothing is left on the bed', token_amount: 5 },
  { name: 'Brush Teeth', description: 'Brush your teeth for 2 minutes', definition_of_done: 'Toothbrush is wet and toothpaste is visible on the brush or sink', token_amount: 2 },
  { name: 'Set Table', description: 'Put plates, glasses, and cutlery on the table', definition_of_done: 'Each place setting has a plate, fork, knife, and glass', token_amount: 3 },
  { name: 'Homework', description: 'Complete all assigned homework', definition_of_done: 'All homework pages are filled in and the homework book is closed', token_amount: 10 },
  { name: 'Tidy Toys', description: 'Put all toys away in their proper places', definition_of_done: 'Floor is clear of toys and the toy box or shelves are tidy', token_amount: 4 }
]

# Each parent gets their own private copy of the chore templates
[parent1, parent2].each do |parent|
  chore_templates.each { |c| parent.chores.create!(c) }
end

game = Game.create!(name: 'Pong', description: 'Classic pong game', token_per_minute: 1)
Game.create!(name: 'Berry Hunt', description: "Count berries with Pyrch! A fun counting game for little learners aged 4–6.", token_per_minute: 1)
Game.create!(name: 'Jungle Runner', description: 'Jump over obstacles in the jungle and rack up points!', token_per_minute: 1)

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
