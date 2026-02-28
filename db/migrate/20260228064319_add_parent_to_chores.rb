class AddParentToChores < ActiveRecord::Migration[7.1]
  def up
    # Phase 1: Add parent_id as nullable
    add_column :chores, :parent_id, :bigint
    add_index :chores, :parent_id
    add_foreign_key :chores, :parents

    # Phase 2: For each existing shared chore, create a per-parent copy and
    # record the mapping (old_id => {parent_id => new_id}) so assignments can be re-pointed
    mapping = {}
    shared_chores = execute("SELECT * FROM chores WHERE parent_id IS NULL").to_a
    parent_ids    = execute("SELECT id FROM parents").map { |r| r["id"].to_i }

    shared_chores.each do |chore|
      mapping[chore["id"].to_i] = {}
      parent_ids.each do |pid|
        result = execute(<<~SQL)
          INSERT INTO chores (name, description, definition_of_done, token_amount, parent_id, created_at, updated_at)
          VALUES (#{connection.quote(chore["name"])}, #{connection.quote(chore["description"])},
                  #{connection.quote(chore["definition_of_done"])}, #{chore["token_amount"].to_i},
                  #{pid}, NOW(), NOW())
          RETURNING id
        SQL
        mapping[chore["id"].to_i][pid] = result.first["id"].to_i
      end
    end

    # Phase 3: Re-point chore_assignments to their parent's copy of the chore
    unless mapping.empty?
      old_ids = mapping.keys
      execute(<<~SQL).each do |row|
        SELECT ca.id, ca.chore_id, ch.parent_id AS child_parent_id
        FROM chore_assignments ca
        JOIN children ch ON ch.id = ca.child_id
        WHERE ca.chore_id IN (#{old_ids.join(',')})
      SQL
        old_id    = row["chore_id"].to_i
        parent_id = row["child_parent_id"].to_i
        new_id    = mapping.dig(old_id, parent_id)
        next unless new_id
        execute("UPDATE chore_assignments SET chore_id = #{new_id} WHERE id = #{row['id'].to_i}")
      end

      # Phase 4: Delete original shared chores (FK-safe: all assignments re-pointed above)
      execute("DELETE FROM chores WHERE parent_id IS NULL")
    end

    # Phase 5: Make parent_id NOT NULL
    change_column_null :chores, :parent_id, false
  end

  def down
    remove_column :chores, :parent_id
  end
end
