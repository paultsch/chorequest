class PublicController < ApplicationController
  # Public access via token; no authentication required

  def show
    @child = Child.find_by(public_token: params[:token])
    return render plain: "Not found", status: :not_found unless @child
    # Prefer date-based assignments (scheduled_on) but also support legacy 'day' weekday assignments
    today = Date.current
    weekday = today.strftime("%A").downcase
    @assignments = @child.chore_assignments
      .includes(chore: :chore_tasks, chore_attempts: { photo_attachment: :blob })
      .where('scheduled_on = ? OR (day IS NOT NULL AND lower(day) = ?)', today, weekday)
      .order(:scheduled_on)

    # Upcoming chores for next 90 days (include completed so parent can see status)
    cutoff = today + 90.days
    @upcoming = @child.chore_assignments
      .includes(chore: :chore_tasks, chore_attempts: { photo_attachment: :blob })
      .where('scheduled_on > ? AND scheduled_on <= ?', today, cutoff)
      .order(:scheduled_on)
  end

  def complete
    @child = Child.find_by(public_token: params[:token])
    return render plain: "Not found", status: :not_found unless @child

    assignment = @child.chore_assignments.find_by(id: params[:id])
    return render plain: "Not found", status: :not_found unless assignment

    assignment.update!(completed: true, approved: false)

    redirect_to public_child_path(params[:token]), notice: "Chore marked completed."
  end

  # GET /public/:token/play
  def play
    @child = Child.find_by(public_token: params[:token])
    return render plain: "Not found", status: :not_found unless @child

    today = Date.current
    weekday = today.strftime("%A").downcase
    @assignments = @child.chore_assignments.where('scheduled_on = ? OR (day IS NOT NULL AND lower(day) = ?)', today, weekday).order(:scheduled_on)

    # Only allow public play selection if all today's assignments are completed and approved
    unless @assignments.any? && @assignments.all? { |a| a.completed == true && a.approved == true }
      redirect_to public_child_path(params[:token]), alert: 'All chores must be completed and approved before playing.' and return
    end

    @games = Game.order(:name)
    render template: 'children/play'
  end

  # GET /public/:token/attempt/:assignment_id
  def new_attempt
    @child = Child.find_by(public_token: params[:token])
    return render plain: "Not found", status: :not_found unless @child

    @chore_assignment = @child.chore_assignments.find_by(id: params[:assignment_id])
    return render plain: "Not found", status: :not_found unless @chore_assignment

    if @chore_assignment.approved == true
      redirect_to public_child_path(params[:token]), alert: 'This chore has already been approved.' and return
    end

    # For whole-chore submissions only: block if there is already a pending attempt with no task
    if params[:chore_task_id].blank? && @chore_assignment.chore_attempts.where(chore_task_id: nil, status: 'pending').exists?
      redirect_to public_child_path(params[:token]), alert: 'This chore is already awaiting review.' and return
    end
  end

  # POST /public/:token/attempt
  def create_attempt
    @child = Child.find_by(public_token: params[:token])
    return render plain: "Not found", status: :not_found unless @child

    @chore_assignment = @child.chore_assignments.find_by(id: params[:chore_assignment_id])
    return render plain: "Not found", status: :not_found unless @chore_assignment

    chore_task_id = params.dig(:chore_attempt, :chore_task_id).presence
    task = chore_task_id ? @chore_assignment.chore.chore_tasks.find_by(id: chore_task_id) : nil

    # Non-photo tasks are auto-approved immediately — no review needed
    auto_approve = task.present? && !task.photo_required?

    # Block duplicate approved/pending attempts for this task
    if chore_task_id.present?
      if @chore_assignment.chore_attempts.where(chore_task_id: chore_task_id, status: %w[pending approved]).exists?
        redirect_to public_child_path(params[:token]), alert: 'This step is already done.' and return
      end
    else
      if @chore_assignment.chore_attempts.where(chore_task_id: nil, status: 'pending').exists?
        redirect_to public_child_path(params[:token]), alert: 'This chore is already awaiting review.' and return
      end
    end

    attempt = @chore_assignment.chore_attempts.build(
      status: auto_approve ? 'approved' : 'pending',
      chore_task_id: chore_task_id
    )
    attempt.photo.attach(params.dig(:chore_attempt, :photo)) if params.dig(:chore_attempt, :photo).present?

    if attempt.valid? && attempt.save
      chore = @chore_assignment.chore
      required_tasks = chore.chore_tasks.where(photo_required: true)

      if required_tasks.any?
        # Chore has photo-required steps — mark completed when all photo tasks have been submitted
        all_submitted = required_tasks.all? { |t| @chore_assignment.chore_attempts.where(chore_task_id: t.id).exists? }
        @chore_assignment.update!(completed: all_submitted, completed_at: all_submitted ? Time.current : nil)
      elsif chore.chore_tasks.any?
        # All tasks are non-photo — auto-approve the assignment when every task is checked off
        all_approved = chore.chore_tasks.all? { |t| @chore_assignment.chore_attempts.where(chore_task_id: t.id, status: 'approved').exists? }
        if all_approved
          @chore_assignment.update!(completed: true, approved: true, completed_at: Time.current)
        end
      else
        @chore_assignment.update!(completed: true, approved: nil, completed_at: Time.current)
      end

      AnalyzeChorePhotoJob.perform_later(attempt.id) if attempt.photo.attached? && !auto_approve
      notice = auto_approve ? 'Step marked done! ✓' : 'Chore submitted for review!'
      redirect_to public_child_path(params[:token]), notice: notice
    else
      render :new_attempt, status: :unprocessable_entity
    end
  end

  # POST /public/:token/start_session
  def start_session
    @child = Child.find_by(public_token: params[:token])
    return render plain: "Not found", status: :not_found unless @child

    game = Game.find_by(id: params[:game_id])
    unless game
      redirect_to public_play_path(params[:token]), alert: 'Game not found' and return
    end

    # prevent multiple active sessions for this child
    active = GameSession.where(child: @child, ended_at: nil).first
    if active
      target = if active.game&.name.to_s.downcase.include?('pong')
        "/games/pong_with_menu.html?session_id=#{active.id}"
      elsif active.game&.name.to_s.downcase.include?('runner')
        "/games/runner.html?session_id=#{active.id}"
      elsif active.game&.name.to_s.downcase.include?('berry')
        "/games/berry-hunt/index.html?session_id=#{active.id}"
      else
        game_path(active.game) + "?session_id=#{active.id}"
      end
      redirect_to target and return
    end

    if @child.token_balance <= 0
      redirect_to public_play_path(params[:token]), alert: 'Child has no tokens to start play.' and return
    end

    # duration_minutes must be > 0 (validation). Start at 1 minute and let heartbeat increment.
    gs = GameSession.create!(child: @child, game: game, started_at: Time.current, duration_minutes: 1, last_heartbeat: Time.current)

    target = if game.name.to_s.downcase.include?('pong')
      "/games/pong_with_menu.html?session_id=#{gs.id}"
    elsif game.name.to_s.downcase.include?('runner')
      "/games/runner.html?session_id=#{gs.id}"
    elsif game.name.to_s.downcase.include?('berry')
      "/games/berry-hunt/index.html?session_id=#{gs.id}"
    else
      game_path(game) + "?session_id=#{gs.id}"
    end
    redirect_to target
  end
end
