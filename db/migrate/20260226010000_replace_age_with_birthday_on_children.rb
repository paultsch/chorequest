class ReplaceAgeWithBirthdayOnChildren < ActiveRecord::Migration[7.1]
  def change
    add_column :children, :birthday, :date
    remove_column :children, :age, :integer
  end
end
