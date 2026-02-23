class AddPublicTokenToChildren < ActiveRecord::Migration[7.1]
  def change
    add_column :children, :public_token, :string
    add_index :children, :public_token, unique: true
  end
end
