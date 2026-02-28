class ChoresController < ApplicationController
  before_action :set_chore, only: %i[ show edit update destroy ]

  # GET /chores or /chores.json
  def index
    # Sorting: only allow name and token_amount for safety
    allowed_sorts = %w[name token_amount]
    sort_col = allowed_sorts.include?(params[:sort]) ? params[:sort] : 'name'
    sort_dir = params[:direction] == 'desc' ? :desc : :asc

    @chores = Chore.includes(:chore_assignments)
                   .order(sort_col => sort_dir)
  end

  # GET /chores/1 or /chores/1.json
  def show
  end

  # GET /chores/new
  def new
    @chore = Chore.new
  end

  # GET /chores/1/edit
  def edit
  end

  # POST /chores or /chores.json
  def create
    @chore = Chore.new(chore_params)

    respond_to do |format|
      if @chore.save
        format.html { redirect_to @chore, notice: "Chore was successfully created." }
        format.json { render :show, status: :created, location: @chore }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @chore.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /chores/1 or /chores/1.json
  def update
    respond_to do |format|
      if @chore.update(chore_params)
        format.html { redirect_to @chore, notice: "Chore was successfully updated.", status: :see_other }
        format.json { render :show, status: :ok, location: @chore }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @chore.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /chores/1 or /chores/1.json
  def destroy
    @chore.destroy!

    respond_to do |format|
      format.html { redirect_to chores_path, notice: "Chore was successfully destroyed.", status: :see_other }
      format.json { head :no_content }
    end
  end

  # POST /chores/improve_definition
  def improve_definition
    name        = params[:name].to_s.strip
    description = params[:description].to_s.strip
    current_dod = params[:definition_of_done].to_s.strip

    return render json: { error: 'Please enter a chore name first.' }, status: :unprocessable_entity if name.blank?

    prompt = <<~PROMPT
      You are helping a parent set up a chore in a children's chore tracking app.

      Generate a complete set of details for the following chore.

      Chore name: #{name}
      #{"Parent's description draft: #{description}" if description.present?}
      #{"Parent's current definition of done: #{current_dod}" if current_dod.present?}

      Return a JSON object with exactly these three keys:
      - "description": 1-2 sentences describing what the chore involves, written simply so a child understands what they need to do.
      - "definition_of_done": 1-3 sentences describing the visible, physical end state (not the actions taken). Must be specific enough for an AI to verify from a single photo. Close obvious loopholes (e.g. "not just pushed aside").
      - "token_amount": An integer between 0 and 200 representing a fair token reward. Base it on effort/time: simple quick tasks = 5–15, moderate tasks = 20–50, harder tasks = 60–100+.

      Return ONLY valid JSON with no explanation and no markdown code fences.
    PROMPT

    client   = Anthropic::Client.new(api_key: ENV.fetch('ANTHROPIC_API_KEY'))
    response = Timeout.timeout(20) do
      client.messages.create(
        model:      'claude-haiku-4-5-20251001',
        max_tokens: 400,
        messages:   [{ role: 'user', content: prompt }]
      )
    end

    raw  = response.content.first.text.strip
    text = raw.gsub(/\A```(?:json)?\n?/, '').gsub(/\n?```\z/, '').strip
    data = JSON.parse(text)

    render json: {
      description:        data['description'].to_s.strip,
      definition_of_done: data['definition_of_done'].to_s.strip,
      token_amount:       data['token_amount'].to_i
    }
  rescue JSON::ParserError => e
    Rails.logger.error "improve_definition JSON parse failed: #{e.message}"
    render json: { error: 'AI returned an unexpected format. Please try again.' }, status: :unprocessable_entity
  rescue => e
    Rails.logger.error "improve_definition failed: #{e.class}: #{e.message}"
    render json: { error: e.message }, status: :unprocessable_entity
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_chore
      @chore = Chore.find(params[:id])
    end

    # Only allow a list of trusted parameters through.
    def chore_params
      params.require(:chore).permit(:name, :description, :definition_of_done, :token_amount)
    end
end
