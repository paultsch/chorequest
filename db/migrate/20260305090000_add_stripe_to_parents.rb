class AddStripeToParents < ActiveRecord::Migration[7.1]
  def change
    add_column :parents, :plan_tier, :string, default: "free", null: false
    add_column :parents, :stripe_customer_id, :string
    add_column :parents, :stripe_subscription_id, :string
    add_column :parents, :subscription_status, :string
    add_column :parents, :trial_ends_at, :datetime

    add_index :parents, :stripe_customer_id, unique: true
    add_index :parents, :stripe_subscription_id, unique: true
  end
end
