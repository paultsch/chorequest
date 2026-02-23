class ChoreAssignmentsController < ApplicationController
  before_action :set_chore_assignment, only: %i[ show edit update destroy mark_complete ]

  # GET /chore_assignments or /chore_assignments.json
  def index
    # Only show assignments for this parent's children in private view
    if current_parent
      @chore_assignments = ChoreAssignment.includes(:child, :chore)
                                           .where(child: current_parent.children)
                                           .order('children.name ASC')
    else
      # non-authenticated users should not see assignments
      @chore_assignments = ChoreAssignment.none
    end
    # Group assignments by child for the card grid
    @assignments_by_child = @chore_assignments.group_by(&:child)
  end

  # POST /chore_assignments/bulk_update
  def bulk_update
    ids = params[:assignment_ids] || []
    action = params[:bulk_action]

    assignments = ChoreAssignment.where(id: ids)
    case action
    when 'approve'
      # Use per-record updates so callbacks run (to grant tokens on approval).
      approved_count = 0
      assignments.find_each do |a|
        approved_count += 1 if a.update(approved: true)
      end
      notice = "Approved #{approved_count} assignment(s)."
    when 'reject'
      rejected_count = 0
      assignments.find_each do |a|
        rejected_count += 1 if a.update(approved: false, completed: false)
      end
      notice = "Rejected #{rejected_count} assignment(s)."
    when 'delete'
      assignments.destroy_all
      notice = "Deleted #{assignments.size} assignment(s)."
    else
      notice = "No action taken."
    end

    redirect_back fallback_location: chore_assignments_path, notice: notice
  end

  # GET /chore_assignments/1 or /chore_assignments/1.json
  def show
  end

  # GET /chore_assignments/new
  def new
    @chore_assignment = ChoreAssignment.new
    if params[:child_id].present?
      @chore_assignment.child_id = params[:child_id]
    end
  end

  # GET /chore_assignments/1/edit
  def edit
  end

  # POST /chore_assignments or /chore_assignments.json
  def create
    # Support creating multiple date-specific assignments when user passes dates_input
    dates_input = params[:chore_assignment].delete(:dates_input)&.to_s&.strip
    mode = params[:chore_assignment].delete(:assignment_mode)
    dates = []
    if dates_input.present?
      if dates_input.start_with?('[')
        begin
          parsed = JSON.parse(dates_input)
          parsed.each { |d| dates << (Date.parse(d.to_s) rescue nil) }
        rescue
          dates = dates_input.split(',').map { |s| Date.parse(s.strip) rescue nil }
        end
      elsif dates_input.include?(' to ')
        parts = dates_input.split(' to ').map(&:strip)
        begin
          start_date = Date.parse(parts[0])
          end_date = Date.parse(parts[1])
          (start_date..end_date).each { |d| dates << d }
        rescue
        end
      elsif dates_input.include?(' - ')
        parts = dates_input.split(' - ').map(&:strip)
        begin
          start_date = Date.parse(parts[0])
          end_date = Date.parse(parts[1])
          (start_date..end_date).each { |d| dates << d }
        rescue
        end
      else
        dates = dates_input.split(',').map { |s| Date.parse(s.strip) rescue nil }
      end
      dates.compact!

      # enforce max days per request
      max_days = 30
      if dates.size > max_days
        redirect_back fallback_location: new_chore_assignment_path, alert: "Date range too large (max #{max_days} days)." and return
      end

      created = 0
      skipped = 0
      dates.each do |date|
        next unless date
        attrs = chore_assignment_params.except(:scheduled_on).merge(scheduled_on: date)
        if ChoreAssignment.exists?(child_id: attrs[:child_id], chore_id: attrs[:chore_id], scheduled_on: date)
          skipped += 1
          next
        end
        ca = ChoreAssignment.new(attrs)
        ca.approved = false if ca.respond_to?(:approved)
        ca.completed = false if ca.respond_to?(:completed)
        created += 1 if ca.save
      end

      notice_parts = []
      notice_parts << "Created #{created} assignment(s)" if created > 0
      notice_parts << "Skipped #{skipped} existing date(s)" if skipped > 0
      notice = notice_parts.join('. ')
      redirect_to child_path(chore_assignment_params[:child_id]), notice: notice and return

      created = []
      parsed.each do |d|
        begin
          date = Date.parse(d)
        rescue => e
          next
        end
        ca = ChoreAssignment.new(chore_assignment_params.merge(scheduled_on: date, day: date.strftime('%A')))
        created << ca if ca.save
      end

      if created.any?
        redirect_to child_path(created.first.child), notice: "Created #{created.size} assignment(s)."
      else
        redirect_to new_chore_assignment_path, alert: "No valid dates provided."
      end
      return
    end

    @chore_assignment = ChoreAssignment.new(chore_assignment_params)

    respond_to do |format|
      if @chore_assignment.save
        # No recurrence expansion here; UI supports single or range creation which is handled above.

        format.html { redirect_to child_path(@chore_assignment.child), notice: "Chore assignment was successfully created." }
        format.json { render :show, status: :created, location: @chore_assignment }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @chore_assignment.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /chore_assignments/1 or /chore_assignments/1.json
  def update
    respond_to do |format|
      if @chore_assignment.update(chore_assignment_params)
        format.html { redirect_to @chore_assignment, notice: "Chore assignment was successfully updated.", status: :see_other }
        format.json { render :show, status: :ok, location: @chore_assignment }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @chore_assignment.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /chore_assignments/1 or /chore_assignments/1.json
  def destroy
    @chore_assignment.destroy!

    respond_to do |format|
      format.html { redirect_to chore_assignments_path, notice: "Chore assignment was successfully destroyed.", status: :see_other }
      format.json { head :no_content }
    end
  end

  # POST /chore_assignments/:id/mark_complete
  def mark_complete
    # When a child marks done, mark completed, set completed_at and ensure approved is false so parent can review
    # Use nil for `approved` to represent "awaiting approval" (parent hasn't acted yet)
    if @chore_assignment.update(completed: true, approved: nil, completed_at: Time.current)
      redirect_back fallback_location: child_path(@chore_assignment.child), notice: "Chore marked complete and pending approval."
    else
      redirect_back fallback_location: child_path(@chore_assignment.child), alert: "Could not mark chore as complete."
    end
  end

  # POST /chore_assignments/:id/approve
  def approve
    ca = @chore_assignment
    if ca.update(approved: true)
      redirect_back fallback_location: admin_dashboard_index_path, notice: 'Assignment approved.'
    else
      redirect_back fallback_location: admin_dashboard_index_path, alert: 'Could not approve.'
    end
  end

  # POST /chore_assignments/:id/reject
  def reject
    ca = @chore_assignment
    if ca.update(approved: false, completed: false)
      redirect_back fallback_location: admin_dashboard_index_path, notice: 'Assignment rejected.'
    else
      redirect_back fallback_location: admin_dashboard_index_path, alert: 'Could not reject.'
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_chore_assignment
      @chore_assignment = ChoreAssignment.find(params[:id])
    end

    # Only allow a list of trusted parameters through.
    def chore_assignment_params
      params.require(:chore_assignment).permit(:child_id, :chore_id, :day, :completed, :approved, :completion_photo, :scheduled_on, extra_dates: [])
    end
end
