class CreateSchoolMessages < ActiveRecord::Migration[7.1]
  def change
    create_table :school_messages do |t|
      t.references :parent, null: false, foreign_key: true
      t.string  :subject
      t.text    :raw_body
      t.string  :from_address
      t.string  :category
      t.string  :child_name
      t.text    :summary
      t.text    :action_item
      t.date    :deadline
      t.boolean :actioned, default: false
      t.boolean :needs_attention, default: true
      t.string  :parse_status, default: "pending"
      t.timestamps
    end

    add_index :school_messages, [:parent_id, :actioned]
    add_index :school_messages, [:parent_id, :needs_attention]
  end
end
