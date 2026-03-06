class CreatePushSubscriptions < ActiveRecord::Migration[7.1]
  def change
    create_table :push_subscriptions do |t|
      t.references :parent, foreign_key: true, null: true
      t.references :child,  foreign_key: true, null: true
      t.string :endpoint,   null: false
      t.string :p256dh,     null: false
      t.string :auth,       null: false
      t.string :platform,   null: false, default: "web"
      t.string :user_agent

      t.timestamps
    end

    add_index :push_subscriptions, :endpoint, unique: true
  end
end
