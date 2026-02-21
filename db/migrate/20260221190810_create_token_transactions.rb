class CreateTokenTransactions < ActiveRecord::Migration[7.1]
  def change
    create_table :token_transactions do |t|
      t.references :child, null: false, foreign_key: true
      t.integer :amount
      t.string :description

      t.timestamps
    end
  end
end
