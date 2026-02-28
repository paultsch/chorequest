class CreateAdminAudits < ActiveRecord::Migration[7.1]
  def change
    create_table :admin_audits do |t|
      t.bigint :admin_id, null: false
      t.string :action
      t.string :auditable_type
      t.bigint :auditable_id
      t.jsonb :metadata, default: {}

      t.timestamps
    end

    add_index :admin_audits, :admin_id
    add_index :admin_audits, [:auditable_type, :auditable_id]
  end
end
