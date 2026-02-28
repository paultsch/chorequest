require "test_helper"

class ChoresControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  setup do
    @chore = chores(:one)
    sign_in parents(:one)
  end

  test "requires authentication" do
    sign_out :parent
    get chores_url
    assert_redirected_to new_parent_session_path
  end

  test "should get index" do
    get chores_url
    assert_response :success
  end

  test "index only shows current parent chores" do
    get chores_url
    assert_response :success
    # chores(:two) belongs to parents(:one) so it should appear
    # A chore belonging to parents(:two) should NOT appear
    chore_for_other_parent = parents(:two).chores.create!(name: "Other Chore", token_amount: 1)
    get chores_url
    assert_select "td", text: "Other Chore", count: 0
  end

  test "should get new" do
    get new_chore_url
    assert_response :success
  end

  test "should create chore" do
    assert_difference("parents(:one).chores.count") do
      post chores_url, params: { chore: { name: "New Chore", description: "desc", definition_of_done: "done", token_amount: 5 } }
    end
    assert_redirected_to chore_url(Chore.last)
  end

  test "should show chore" do
    get chore_url(@chore)
    assert_response :success
  end

  test "cannot show another parent's chore" do
    other_chore = parents(:two).chores.create!(name: "Bob's Chore", token_amount: 1)
    get chore_url(other_chore)
    assert_response :not_found
  end

  test "should get edit" do
    get edit_chore_url(@chore)
    assert_response :success
  end

  test "cannot edit another parent's chore" do
    other_chore = parents(:two).chores.create!(name: "Bob's Chore", token_amount: 1)
    get edit_chore_url(other_chore)
    assert_response :not_found
  end

  test "should update chore" do
    patch chore_url(@chore), params: { chore: { name: "Updated Name" } }
    assert_redirected_to chore_url(@chore)
  end

  test "cannot update another parent's chore" do
    other_chore = parents(:two).chores.create!(name: "Bob's Chore", token_amount: 1)
    patch chore_url(other_chore), params: { chore: { name: "Hacked" } }
    assert_response :not_found
    other_chore.reload
    assert_equal "Bob's Chore", other_chore.name
  end

  test "should destroy chore" do
    assert_difference("parents(:one).chores.count", -1) do
      delete chore_url(@chore)
    end
    assert_redirected_to chores_url
  end

  test "cannot destroy another parent's chore" do
    other_chore = parents(:two).chores.create!(name: "Bob's Chore", token_amount: 1)
    assert_no_difference("Chore.count") do
      delete chore_url(other_chore)
    end
    assert_response :not_found
  end
end
