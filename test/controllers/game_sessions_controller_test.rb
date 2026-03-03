require "test_helper"

class GameSessionsControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  setup do
    @parent = parents(:one)
    @parent_two = parents(:two)
    @child_one = children(:one)
    @child_two = children(:two)
    @game_one = games(:one)
    @game_two = games(:two)
    @game_session = game_sessions(:one)
    @game_session_two = game_sessions(:two)
  end

  # Authentication gate tests for parent actions

  test "unauthenticated request to index redirects to sign-in" do
    get game_sessions_url
    assert_redirected_to new_parent_session_path
  end

  test "unauthenticated request to new redirects to sign-in" do
    get new_game_session_url
    assert_redirected_to new_parent_session_path
  end

  test "unauthenticated request to create redirects to sign-in" do
    post game_sessions_url, params: { game_session: { child_id: @child_one.id, game_id: @game_one.id, duration_minutes: 5, started_at: Time.current } }
    assert_redirected_to new_parent_session_path
  end

  test "unauthenticated request to show redirects to sign-in" do
    get game_session_url(@game_session)
    assert_redirected_to new_parent_session_path
  end

  test "unauthenticated request to edit redirects to sign-in" do
    get edit_game_session_url(@game_session)
    assert_redirected_to new_parent_session_path
  end

  # Happy path tests - authenticated parent can perform actions

  test "authenticated parent can view index" do
    sign_in @parent
    get game_sessions_url
    assert_response :success
  end

  test "authenticated parent can view their own child's game session" do
    sign_in @parent
    get game_session_url(@game_session)
    assert_response :success
  end

  test "authenticated parent can get new game_session form" do
    sign_in @parent
    get new_game_session_url
    assert_response :success
  end

  test "authenticated parent can edit their own game session" do
    sign_in @parent
    get edit_game_session_url(@game_session)
    assert_response :success
  end

  # Cross-parent isolation tests

  test "parent cannot view another parent's child's game session" do
    sign_in @parent_two
    # @game_session belongs to @child_one which belongs to @parent
    get game_session_url(@game_session)
    assert_response :not_found
  end

  test "parent cannot edit another parent's child's game session" do
    sign_in @parent_two
    get edit_game_session_url(@game_session)
    assert_response :not_found
  end

  test "parent cannot destroy another parent's child's game session" do
    sign_in @parent_two
    assert_no_difference("GameSession.count") do
      delete game_session_url(@game_session)
    end
    assert_response :not_found
  end

  # Child_id ownership validation in create

  test "create rejects invalid child_id" do
    sign_in @parent
    assert_no_difference("GameSession.count") do
      post game_sessions_url, params: { game_session: { child_id: 99999, game_id: @game_one.id, duration_minutes: 5, started_at: Time.current } }
    end
    assert_redirected_to game_sessions_path
    assert_match /Invalid child/, flash[:alert]
  end

  test "create rejects foreign child_id (another parent's child)" do
    sign_in @parent
    assert_no_difference("GameSession.count") do
      post game_sessions_url, params: { game_session: { child_id: @child_two.id, game_id: @game_one.id, duration_minutes: 5, started_at: Time.current } }
    end
    assert_redirected_to game_sessions_path
    assert_match /Invalid child/, flash[:alert]
  end

  # Duration minimum validation

  test "create enforces minimum duration_minutes of 1" do
    sign_in @parent
    # Ensure child has tokens
    @child_one.token_transactions.create!(amount: 100, description: "Setup tokens")

    # Try to create with duration_minutes = 0
    assert_difference("GameSession.count") do
      post game_sessions_url, params: { game_session: { child_id: @child_one.id, game_id: @game_one.id, duration_minutes: 0, started_at: Time.current } }
    end

    # Verify that the session was created with duration_minutes = 1
    session = GameSession.last
    assert_equal 1, session.duration_minutes
  end

  test "create enforces minimum duration_minutes when nil" do
    sign_in @parent
    @child_one.token_transactions.create!(amount: 100, description: "Setup tokens")

    assert_difference("GameSession.count") do
      post game_sessions_url, params: { game_session: { child_id: @child_one.id, game_id: @game_one.id, duration_minutes: nil, started_at: Time.current } }
    end

    session = GameSession.last
    assert_equal 1, session.duration_minutes
  end

  # Heartbeat ownership and authorization tests

  test "heartbeat with a session belonging to a different child is rejected" do
    sign_in @parent_two
    # Try to call heartbeat on @game_session which belongs to @child_one
    post game_session_heartbeat_path(@game_session), params: {}, as: :json
    assert_response :unauthorized
  end

  test "heartbeat without authentication is rejected when session belongs to another child" do
    # Don't sign in, just try to heartbeat with wrong session
    # Set up child session for child_two instead
    post game_session_heartbeat_path(@game_session), params: {}, as: :json
    assert_response :unauthorized
  end

  test "heartbeat is allowed for child with correct session" do
    # Simulate child session
    post game_session_heartbeat_path(@game_session), params: {}, session: { child_id: @child_one.id }, as: :json
    assert_response :success
    assert_match /ended/, response.body
  end

  test "heartbeat is allowed for parent of the game session's child" do
    sign_in @parent
    post game_session_heartbeat_path(@game_session), params: {}, as: :json
    assert_response :success
    assert_match /ended/, response.body
  end

  # Stop action ownership tests

  test "stop with a session belonging to a different child is rejected" do
    sign_in @parent_two
    # Try to call stop on @game_session which belongs to @child_one
    post game_session_stop_path(@game_session), params: {}, as: :json
    assert_response :unauthorized
  end

  test "stop is allowed for parent of the game session's child" do
    sign_in @parent
    post game_session_stop_path(@game_session), params: {}, as: :json
    assert_response :success
    assert_match /stopped/, response.body
  end
end
