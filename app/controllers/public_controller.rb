class PublicController < ApplicationController
  # Public access via token; no authentication required

  def show
    @child = Child.find_by(public_token: params[:token])
    return render plain: "Not found", status: :not_found unless @child
    # Prefer date-based assignments (scheduled_on) but also support legacy 'day' weekday assignments
    today = Date.current
    weekday = today.strftime("%A").downcase
    @assignments = @child.chore_assignments.where('scheduled_on = ? OR (day IS NOT NULL AND lower(day) = ?)', today, weekday).order(:scheduled_on)

    # Upcoming chores for next 90 days (include completed so parent can see status)
    cutoff = today + 90.days
    @upcoming = @child.chore_assignments.where('scheduled_on > ? AND scheduled_on <= ?', today, cutoff).order(:scheduled_on)
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

    if @chore_assignment.pending_attempt?
      redirect_to public_child_path(params[:token]), alert: 'This chore is already awaiting review.' and return
    end
    if @chore_assignment.approved == true
      redirect_to public_child_path(params[:token]), alert: 'This chore has already been approved.' and return
    end
  end

  # POST /public/:token/attempt
  def create_attempt
    @child = Child.find_by(public_token: params[:token])
    return render plain: "Not found", status: :not_found unless @child

    @chore_assignment = @child.chore_assignments.find_by(id: params[:chore_assignment_id])
    return render plain: "Not found", status: :not_found unless @chore_assignment

    if @chore_assignment.pending_attempt?
      redirect_to public_child_path(params[:token]), alert: 'This chore is already awaiting review.' and return
    end

    attempt = @chore_assignment.chore_attempts.build(status: 'pending')
    attempt.photo.attach(params.dig(:chore_attempt, :photo)) if params.dig(:chore_attempt, :photo).present?

    if attempt.valid? && attempt.save
      @chore_assignment.update!(completed: true, approved: nil, completed_at: Time.current)
      AnalyzeChorePhotoJob.perform_later(attempt.id) if attempt.photo.attached?
      redirect_to public_child_path(params[:token]), notice: 'Chore submitted for review!'
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
