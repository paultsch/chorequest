require "application_system_test_case"

class ChoresTest < ApplicationSystemTestCase
  setup do
    @chore = chores(:one)
  end

  test "visiting the index" do
    visit chores_url
    assert_selector "h1", text: "Chores"
  end

  test "should create chore" do
    visit chores_url
    click_on "New chore"

    fill_in "Definition of done", with: @chore.definition_of_done
    fill_in "Description", with: @chore.description
    fill_in "Name", with: @chore.name
    fill_in "Recurrence", with: @chore.recurrence
    fill_in "Token amount", with: @chore.token_amount
    click_on "Create Chore"

    assert_text "Chore was successfully created"
    click_on "Back"
  end

  test "should update Chore" do
    visit chore_url(@chore)
    click_on "Edit this chore", match: :first

    fill_in "Definition of done", with: @chore.definition_of_done
    fill_in "Description", with: @chore.description
    fill_in "Name", with: @chore.name
    fill_in "Recurrence", with: @chore.recurrence
    fill_in "Token amount", with: @chore.token_amount
    click_on "Update Chore"

    assert_text "Chore was successfully updated"
    click_on "Back"
  end

  test "should destroy Chore" do
    visit chore_url(@chore)
    click_on "Destroy this chore", match: :first

    assert_text "Chore was successfully destroyed"
  end
end
