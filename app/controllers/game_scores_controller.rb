class GameScoresController < ApplicationController
  skip_before_action :verify_authenticity_token, only: [:create]

  # POST /game_scores
  def create
    # Scores must be tied to a verified game session — no anonymous child_id/game_id submissions.
    unless params[:session_id].present?
      return render json: { error: 'session_id required' }, status: :unprocessable_entity
    end

    gs = GameSession.find_by(id: params[:session_id])
    return render json: { error: 'session not found' }, status: :not_found unless gs

    # Verify the caller owns this session (child playing or owning parent).
    authorized = (session[:child_id].present? && gs.child_id.to_s == session[:child_id].to_s) ||
                 (parent_signed_in? && current_parent.children.exists?(id: gs.child_id))
    return render json: { error: 'unauthorized' }, status: :unauthorized unless authorized

    child = gs.child
    game  = gs.game

    return render json: { error: 'missing child or game' }, status: :unprocessable_entity unless child && game

    score = params[:score].to_i
    gs_record = GameScore.create!(child: child, game: game, score: score)
    render json: { id: gs_record.id, score: gs_record.score }, status: :created
  rescue ActiveRecord::RecordInvalid => e
    render json: { error: e.record.errors.full_messages.join(', ') }, status: :unprocessable_entity
  end
end
