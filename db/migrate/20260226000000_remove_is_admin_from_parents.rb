class RemoveIsAdminFromParents < ActiveRecord::Migration[7.1]
  def change
    remove_column :parents, :is_admin, :boolean
  end
end
