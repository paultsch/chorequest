require "application_system_test_case"

class GameSessionsTest < ApplicationSystemTestCase
  setup do
    @game_session = game_sessions(:one)
  end

  test "visiting the index" do
    visit game_sessions_url
    assert_selector "h1", text: "Game sessions"
  end

  test "should create game session" do
    visit game_sessions_url
    click_on "New game session"

    fill_in "Child", with: @game_session.child_id
    fill_in "Duration minutes", with: @game_session.duration_minutes
    fill_in "Ended at", with: @game_session.ended_at
    fill_in "Game", with: @game_session.game_id
    fill_in "Started at", with: @game_session.started_at
    click_on "Create Game session"

    assert_text "Game session was successfully created"
    click_on "Back"
  end

  test "should update Game session" do
    visit game_session_url(@game_session)
    click_on "Edit this game session", match: :first

    fill_in "Child", with: @game_session.child_id
    fill_in "Duration minutes", with: @game_session.duration_minutes
    fill_in "Ended at", with: @game_session.ended_at
    fill_in "Game", with: @game_session.game_id
    fill_in "Started at", with: @game_session.started_at
    click_on "Update Game session"

    assert_text "Game session was successfully updated"
    click_on "Back"
  end

  test "should destroy Game session" do
    visit game_session_url(@game_session)
    click_on "Destroy this game session", match: :first

    assert_text "Game session was successfully destroyed"
  end
end
