class GameScoresController < ApplicationController
  skip_before_action :verify_authenticity_token, only: [:create]

  # POST /game_scores
  def create
    # Accept either session_id or child_id+game_id
    if params[:session_id].present?
      gs = GameSession.find_by(id: params[:session_id])
      return render json: { error: 'session not found' }, status: :not_found unless gs
      child = gs.child
      game = gs.game
    else
      child = Child.find_by(id: params[:child_id])
      game = Game.find_by(id: params[:game_id])
    end

    return render json: { error: 'missing child or game' }, status: :unprocessable_entity unless child && game

    score = params[:score].to_i
    gs_record = GameScore.create!(child: child, game: game, score: score)
    render json: { id: gs_record.id, score: gs_record.score }, status: :created
  rescue ActiveRecord::RecordInvalid => e
    render json: { error: e.record.errors.full_messages.join(', ') }, status: :unprocessable_entity
  end
end
