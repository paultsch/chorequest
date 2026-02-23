class AddSignupFieldsToParents < ActiveRecord::Migration[7.1]
  def change
    add_column :parents, :display_name, :string
    add_column :parents, :phone, :string
    add_column :parents, :accepted_terms, :boolean, default: false, null: false
  end
end
