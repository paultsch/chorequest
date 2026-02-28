module ChoreAssignmentsHelper
  # Returns an array of weeks for the given month, each week being an array of 7 Date objects.
  # Pads with days from adjacent months so each row is a full Sun–Sat week.
  def calendar_weeks(year, month)
    first = Date.new(year, month, 1)
    last  = first.end_of_month
    start = first.beginning_of_week(:sunday)
    stop  = last.end_of_week(:sunday)
    (start..stop).to_a.each_slice(7).to_a
  end

  # Returns the 7 Date objects for the week starting on week_start (Sunday).
  def calendar_week_days(week_start)
    (0..6).map { |i| week_start + i.days }
  end

  # Build the prev/next month navigation path
  def prev_month_path(year, month, child_id)
    prev = Date.new(year, month, 1).prev_month
    chore_assignments_path(view: 'month', year: prev.year, month: prev.month, child_id: child_id)
  end

  def next_month_path(year, month, child_id)
    nxt = Date.new(year, month, 1).next_month
    chore_assignments_path(view: 'month', year: nxt.year, month: nxt.month, child_id: child_id)
  end

  # Build the prev/next week navigation path
  def prev_week_path(week_start, child_id)
    chore_assignments_path(view: 'week', week_start: (week_start - 7).iso8601, child_id: child_id)
  end

  def next_week_path(week_start, child_id)
    chore_assignments_path(view: 'week', week_start: (week_start + 7).iso8601, child_id: child_id)
  end
end
