class ExpandRecurrenceAndAddUniqueIndex < ActiveRecord::Migration[7.0]
  disable_ddl_transaction!

  def up
    say_with_time "Expanding recurring chore_assignments into individual dated records" do
      # Use model to iterate existing recurrence rows
      require Rails.root.join('app','models','chore_assignment').to_s
      ChoreAssignment.reset_column_information

      ChoreAssignment.where.not(recurrence: [nil, '']).find_each do |ca|
        next unless ca.scheduled_on && ca.recurrence_end_on
        start_date = ca.scheduled_on
        end_date = ca.recurrence_end_on
        freq = ca.recurrence
        current = start_date
        while true
          case freq
          when 'daily'
            current = current + 1
          when 'weekly'
            current = current + 7
          when 'monthly'
            current = current.next_month
          else
            break
          end
          break if current > end_date
          unless ChoreAssignment.exists?(child_id: ca.child_id, chore_id: ca.chore_id, scheduled_on: current)
            ChoreAssignment.create!(child_id: ca.child_id, chore_id: ca.chore_id, scheduled_on: current, day: current.strftime('%A'), approved: false, completed: false)
          end
        end
        ca.update_columns(recurrence: nil, recurrence_end_on: nil)
      end
    end

    # Add a unique index to prevent future duplicates
    unless index_exists?(:chore_assignments, [:child_id, :chore_id, :scheduled_on], name: 'index_chore_assignments_on_child_chore_scheduled_on')
      add_index :chore_assignments, [:child_id, :chore_id, :scheduled_on], unique: true, name: 'index_chore_assignments_on_child_chore_scheduled_on'
    end

    # Remove recurrence columns as they are no longer needed
    if column_exists?(:chore_assignments, :recurrence)
      remove_column :chore_assignments, :recurrence
    end
    if column_exists?(:chore_assignments, :recurrence_end_on)
      remove_column :chore_assignments, :recurrence_end_on
    end
  end

  def down
    # Re-create recurrence columns (best-effort) and remove unique index
    unless column_exists?(:chore_assignments, :recurrence)
      add_column :chore_assignments, :recurrence, :string
    end
    unless column_exists?(:chore_assignments, :recurrence_end_on)
      add_column :chore_assignments, :recurrence_end_on, :date
    end

    if index_exists?(:chore_assignments, name: 'index_chore_assignments_on_child_chore_scheduled_on')
      remove_index :chore_assignments, name: 'index_chore_assignments_on_child_chore_scheduled_on'
    end
  end
end
