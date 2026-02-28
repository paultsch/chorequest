class AddArchivedAtToParents < ActiveRecord::Migration[7.1]
  def change
    add_column :parents, :archived_at, :datetime
    add_index :parents, :archived_at
  end
end
