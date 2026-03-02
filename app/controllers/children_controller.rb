class ChildrenController < ApplicationController
  before_action :set_child, only: %i[ show edit update destroy regenerate_public_link play start_session ]

  # GET /children or /children.json
  def index
    # Pagination params
    per_page = 10
    page = params[:page].to_i > 0 ? params[:page].to_i : 1

    # Sorting (only by name supported for now)
    sort_dir = params[:direction] == 'desc' ? :desc : :asc

    scope = current_parent.children
    @total_count = scope.count
    @total_pages = (@total_count / per_page.to_f).ceil

    @children = scope.includes(:parent, :chore_assignments, :token_transactions)
                     .order(name: sort_dir)
                     .offset((page - 1) * per_page)
                     .limit(per_page)
    @page = page
  end

  # GET /children/1 or /children/1.json
  def show
  end

  # POST /children/:id/play
  def play
    # Only allow play if all today's chores are completed
    today = Date.current
    incomplete = @child.chore_assignments.where(scheduled_on: today).where(completed: [false, nil]).exists?
    unless incomplete
      # Check token balance (informational for now)
      balance = @child.token_balance
      if balance <= 0
        redirect_to @child, alert: 'Cannot play: child has no tokens. Please earn tokens by completing chores.' and return
      end
      # Render a small play selection page where parent/child can choose a game to start
      @games = Game.order(:name)
      render :play and return
    end

    redirect_to @child, alert: 'Complete all chores scheduled for today before playing.'
  end

  # POST /children/:id/start_session
  def start_session
    # params: game_id
    game = Game.find_by(id: params[:game_id])
    unless game
      redirect_to play_child_path(@child), alert: 'Game not found' and return
    end

    # prevent multiple active sessions for this child
    active = GameSession.where(child: @child, ended_at: nil).first
    if active
      # redirect to existing session's game URL
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

    # ensure child has at least 1 token
    if @child.token_balance <= 0
      redirect_to play_child_path(@child), alert: 'Child has no tokens to start play.' and return
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

  # GET /children/new
  def new
    @child = Child.new
  end

  # GET /children/1/edit
  def edit
  end

  # POST /children or /children.json
  def create
    @child = current_parent.children.build(child_params)

    respond_to do |format|
      if @child.save
        format.html { redirect_to @child, notice: "Child was successfully created." }
        format.json { render :show, status: :created, location: @child }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @child.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /children/1 or /children/1.json
  def update
    respond_to do |format|
      if @child.update(child_params)
        format.html { redirect_to @child, notice: "Child was successfully updated.", status: :see_other }
        format.json { render :show, status: :ok, location: @child }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @child.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /children/1 or /children/1.json
  def destroy
    @child.destroy!

    respond_to do |format|
      format.html { redirect_to children_path, notice: "Child was successfully destroyed.", status: :see_other }
      format.json { head :no_content }
    end
  end

  # POST /children/:id/regenerate_public_link
  def regenerate_public_link
    @child.generate_public_token!
    redirect_to @child, notice: "Public link generated. Share it with your child."
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_child
      @child = current_parent.children.find(params[:id])
    end

    # Only allow a list of trusted parameters through.
    def child_params
      params.require(:child).permit(:name, :birthday, :pin_code)
    end
end
