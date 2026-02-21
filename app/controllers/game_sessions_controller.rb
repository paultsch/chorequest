class GameSessionsController < ApplicationController
  before_action :set_game_session, only: %i[ show edit update destroy ]

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

    respond_to do |format|
      if @game_session.save
        format.html { redirect_to @game_session, notice: "Game session was successfully created." }
        format.json { render :show, status: :created, location: @game_session }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @game_session.errors, status: :unprocessable_entity }
      end
    end
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
