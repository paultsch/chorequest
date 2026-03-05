class AddRueHistoryToParents < ActiveRecord::Migration[7.1]
  def change
    add_column :parents, :rue_history, :text
  end
end
