class ChoreAttemptsController < ApplicationController
  before_action :authenticate_parent!

  def new
    @chore_assignment = current_parent.children
                                      .map(&:chore_assignments)
                                      .flatten
                                      .find { |ca| ca.id == params[:chore_assignment_id].to_i }
    unless @chore_assignment
      redirect_to children_path, alert: 'Assignment not found.' and return
    end

    if @chore_assignment.pending_attempt?
      redirect_back fallback_location: child_path(@chore_assignment.child),
                    alert: 'This chore is already awaiting review.' and return
    end

    if @chore_assignment.approved == true
      redirect_back fallback_location: child_path(@chore_assignment.child),
                    alert: 'This chore has already been approved.' and return
    end

    @chore_attempt = ChoreAttempt.new
  end

  def create
    assignment_id = params[:chore_assignment_id].to_i
    @chore_assignment = ChoreAssignment.joins(child: :parent)
                                       .where(children: { parent_id: current_parent.id })
                                       .find_by(id: assignment_id)

    unless @chore_assignment
      redirect_to children_path, alert: 'Assignment not found.' and return
    end

    if @chore_assignment.pending_attempt?
      redirect_back fallback_location: child_path(@chore_assignment.child),
                    alert: 'This chore is already awaiting review.' and return
    end

    if @chore_assignment.approved == true
      redirect_back fallback_location: child_path(@chore_assignment.child),
                    alert: 'This chore has already been approved.' and return
    end

    chore_task_id = params.dig(:chore_attempt, :chore_task_id).presence
    @chore_attempt = @chore_assignment.chore_attempts.build(
      status: 'pending',
      chore_task_id: chore_task_id
    )
    @chore_attempt.photo.attach(params[:chore_attempt][:photo]) if params.dig(:chore_attempt, :photo).present?

    if @chore_attempt.valid? && @chore_attempt.save
      @chore_assignment.update(completed: true, approved: nil, completed_at: Time.current)
      redirect_to child_path(@chore_assignment.child),
                  notice: 'Chore submitted for review!'
    else
      render :new, status: :unprocessable_entity
    end
  end

  def approve
    @attempt = find_attempt_for_parent
    unless @attempt
      redirect_to admin_root_path, alert: 'Attempt not found.' and return
    end

    @attempt.update!(status: 'approved')
    assignment = @attempt.chore_assignment

    if all_required_tasks_approved?(assignment)
      assignment.update!(approved: true, completed: true, completed_at: @attempt.updated_at)
      TokenTransaction.create!(
        child: @attempt.child,
        amount: @attempt.chore.token_amount || 0,
        description: "Chore approved: #{@attempt.chore.name}"
      )
      redirect_back fallback_location: admin_root_path, notice: 'Attempt approved! Tokens granted.'
    else
      redirect_back fallback_location: admin_root_path, notice: 'Step approved! Waiting for other steps to be approved.'
    end
  end

  def bulk_approve
    ids = Array(params[:attempt_ids])
    approved_count = 0

    ids.each do |id|
      attempt = ChoreAttempt.joins(chore_assignment: :child)
                            .where(children: { parent_id: current_parent.id })
                            .find_by(id: id)
      next unless attempt&.status_pending?

      attempt.update!(status: 'approved')
      assignment = attempt.chore_assignment
      if all_required_tasks_approved?(assignment)
        assignment.update!(approved: true, completed: true, completed_at: attempt.updated_at)
        TokenTransaction.create!(
          child: attempt.child,
          amount: attempt.chore.token_amount || 0,
          description: "Chore approved: #{attempt.chore.name}"
        )
      end
      approved_count += 1
    end

    redirect_to admin_root_path, notice: "#{approved_count} chore(s) approved!"
  end

  def reject
    @attempt = find_attempt_for_parent
    unless @attempt
      redirect_to admin_root_path, alert: 'Attempt not found.' and return
    end

    @attempt.update!(status: 'rejected', parent_note: params[:parent_note].presence)
    @attempt.chore_assignment.update!(completed: false, approved: nil)

    redirect_back fallback_location: admin_root_path, notice: 'Attempt rejected.'
  end

  private

  def find_attempt_for_parent
    child_ids = current_parent.children.select(:id)
    ChoreAttempt.joins(chore_assignment: :child)
                .where(children: { parent_id: current_parent.id })
                .find_by(id: params[:id])
  end

  # Returns true when there are no photo_required tasks (simple chore, approve immediately)
  # or when every photo_required task now has an approved ChoreAttempt.
  def all_required_tasks_approved?(assignment)
    required_tasks = assignment.chore.chore_tasks.where(photo_required: true)
    return true if required_tasks.empty?

    required_tasks.all? do |task|
      assignment.chore_attempts.where(chore_task_id: task.id, status: 'approved').exists?
    end
  end
end
