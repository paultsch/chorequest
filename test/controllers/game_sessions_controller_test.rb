require "test_helper"

class GameSessionsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @game_session = game_sessions(:one)
  end

  test "should get index" do
    get game_sessions_url
    assert_response :success
  end

  test "should get new" do
    get new_game_session_url
    assert_response :success
  end

  test "should create game_session" do
    assert_difference("GameSession.count") do
      post game_sessions_url, params: { game_session: { child_id: @game_session.child_id, duration_minutes: @game_session.duration_minutes, ended_at: @game_session.ended_at, game_id: @game_session.game_id, started_at: @game_session.started_at } }
    end

    assert_redirected_to game_session_url(GameSession.last)
  end

  test "should show game_session" do
    get game_session_url(@game_session)
    assert_response :success
  end

  test "should get edit" do
    get edit_game_session_url(@game_session)
    assert_response :success
  end

  test "should update game_session" do
    patch game_session_url(@game_session), params: { game_session: { child_id: @game_session.child_id, duration_minutes: @game_session.duration_minutes, ended_at: @game_session.ended_at, game_id: @game_session.game_id, started_at: @game_session.started_at } }
    assert_redirected_to game_session_url(@game_session)
  end

  test "should destroy game_session" do
    assert_difference("GameSession.count", -1) do
      delete game_session_url(@game_session)
    end

    assert_redirected_to game_sessions_url
  end
end
