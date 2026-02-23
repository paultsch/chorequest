class GameSessionsController < ApplicationController
  before_action :set_game_session, only: %i[ show edit update destroy heartbeat stop ]
  skip_before_action :verify_authenticity_token, only: %i[ heartbeat stop ]

  # GET /game_sessions or /game_sessions.json
  def index
    @game_sessions = GameSession.all
  end

  # GET /game_sessions/1 or /game_sessions/1.json
  def show
  end

  # GET /game_sessions/new
  def new
    @game_session = GameSession.new
  end

  # GET /game_sessions/1/edit
  def edit
  end

  # POST /game_sessions or /game_sessions.json
  def create
    @game_session = GameSession.new(game_session_params)

    # Deduct tokens for the requested duration
    game = Game.find_by(id: @game_session.game_id)
    child = Child.find_by(id: @game_session.child_id)
    if game && child
      cost = (game.token_per_minute || 0) * (@game_session.duration_minutes || 0)
      if child.token_balance < cost
        @game_session.errors.add(:base, 'Not enough tokens')
      else
        TokenTransaction.create!(child: child, amount: -cost, description: "Started game: #{game.name}")
      end
    end

    respond_to do |format|
      if @game_session.save
        # initialize heartbeat
        @game_session.update_column(:last_heartbeat, Time.current)
        format.html { redirect_to @game_session, notice: "Game session was successfully created." }
        format.json { render :show, status: :created, location: @game_session }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @game_session.errors, status: :unprocessable_entity }
      end
    end
  end

  # POST /game_sessions/:id/heartbeat
  def heartbeat
    game = @game_session.game
    child = @game_session.child
    price_per_minute = (game&.token_per_minute || 1).to_i

    last = @game_session.last_heartbeat || @game_session.started_at || Time.current
    elapsed = Time.current - last
    minutes = (elapsed / 60).floor

    deducted = 0
    ended = false
    remaining = child.token_balance

    if minutes > 0
      # Use row-level locking on the child to avoid race conditions
      child.with_lock do
        remaining = child.token_balance
        max_minutes = remaining / price_per_minute
        use_minutes = [minutes, max_minutes].min
        if use_minutes > 0
          TokenTransaction.create!(child: child, amount: - (use_minutes * price_per_minute), description: "Game play deduction")
          @game_session.duration_minutes = (@game_session.duration_minutes || 0) + use_minutes
          deducted = use_minutes
        end
        if use_minutes < minutes || (child.reload.token_balance) <= 0
          # end session due to insufficient tokens
          @game_session.ended_at = Time.current
          @game_session.stopped_early = true
          ended = true
        end
        @game_session.last_heartbeat = Time.current
        @game_session.save!
        remaining = child.reload.token_balance
      end
    else
      remaining = child.token_balance
    end

    render json: { ended: ended, deducted_minutes: deducted, remaining_tokens: remaining }
  end

  # POST /game_sessions/:id/stop
  def stop
    @game_session.ended_at ||= Time.current
    @game_session.save!
    render json: { stopped: true, duration_minutes: @game_session.duration_minutes }
  end

  # PATCH/PUT /game_sessions/1 or /game_sessions/1.json
  def update
    respond_to do |format|
      if @game_session.update(game_session_params)
        format.html { redirect_to @game_session, notice: "Game session was successfully updated.", status: :see_other }
        format.json { render :show, status: :ok, location: @game_session }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @game_session.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /game_sessions/1 or /game_sessions/1.json
  def destroy
    @game_session.destroy!

    respond_to do |format|
      format.html { redirect_to game_sessions_path, notice: "Game session was successfully destroyed.", status: :see_other }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_game_session
      @game_session = GameSession.find(params[:id])
    end

    # Only allow a list of trusted parameters through.
    def game_session_params
      params.require(:game_session).permit(:child_id, :game_id, :duration_minutes, :started_at, :ended_at)
    end
end
