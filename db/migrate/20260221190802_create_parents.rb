class CreateParents < ActiveRecord::Migration[7.1]
  def change
    create_table :parents do |t|
      t.string :name
      t.string :email
      t.string :password_digest
      t.boolean :is_admin

      t.timestamps
    end
  end
end
