class AddFrequencyDaysToChores < ActiveRecord::Migration[7.1]
  def change
    add_column :chores, :frequency_days, :integer
  end
end
