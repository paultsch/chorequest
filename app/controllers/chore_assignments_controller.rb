class ChoreAssignmentsController < ApplicationController
  before_action :set_chore_assignment, only: %i[ show edit update destroy ]

  # GET /chore_assignments — drag-and-drop scheduler
  def index
    @children = current_parent.children.order(:name)
    @chores   = current_parent.chores.order(:name)
    @selected_child = @children.find_by(id: params[:child_id]) || @children.first
    @view = params[:view].presence_in(%w[month week]) || 'month'
    today = Date.current

    if @view == 'month'
      @year  = (params[:year]  || today.year).to_i
      @month = (params[:month] || today.month).to_i
      @period_start = Date.new(@year, @month, 1)
      @period_end   = @period_start.end_of_month
    else
      @week_start   = params[:week_start].present? ? Date.parse(params[:week_start]) : today.beginning_of_week(:sunday)
      @period_start = @week_start
      @period_end   = @week_start + 6.days
    end

    @assignments_by_date = if @selected_child
      @selected_child.chore_assignments.includes(:chore)
        .where(scheduled_on: @period_start..@period_end)
        .group_by { |a| a.scheduled_on.to_s }
    else
      {}
    end
  end

  # POST /chore_assignments/bulk_update
  def bulk_update
    ids = params[:assignment_ids] || []
    action = params[:bulk_action]

    assignments = ChoreAssignment.where(id: ids, child: current_parent.children)
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

    # Verify submitted chore belongs to the current parent
    chore = current_parent.chores.find_by(id: chore_assignment_params[:chore_id])
    if chore.nil?
      redirect_back fallback_location: new_chore_assignment_path, alert: "Invalid chore selected."
      return
    end

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
        format.json {
          render json: {
            id:           @chore_assignment.id,
            chore_id:     @chore_assignment.chore_id,
            child_id:     @chore_assignment.child_id,
            scheduled_on: @chore_assignment.scheduled_on.iso8601,
            chore_name:   @chore_assignment.chore.name,
            token_amount: @chore_assignment.chore.token_amount
          }, status: :created
        }
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
        format.json {
          render json: {
            id:            @chore_assignment.id,
            require_photo: @chore_assignment.require_photo?
          }, status: :ok
        }
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

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_chore_assignment
      @chore_assignment = ChoreAssignment.where(child: current_parent.children).find(params[:id])
    end

    # Only allow a list of trusted parameters through.
    def chore_assignment_params
      params.require(:chore_assignment).permit(:child_id, :chore_id, :day, :completed, :approved, :require_photo, :scheduled_on, extra_dates: [])
    end
end
