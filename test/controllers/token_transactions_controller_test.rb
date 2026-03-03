require "test_helper"

class TokenTransactionsControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  setup do
    @parent = parents(:one)
    @parent_two = parents(:two)
    @child_one = children(:one)
    @child_two = children(:two)
    @token_transaction = token_transactions(:one)
  end

  # Authentication gate tests

  test "unauthenticated request to index redirects to sign-in" do
    get token_transactions_url
    assert_redirected_to new_parent_session_path
  end

  test "unauthenticated request to new redirects to sign-in" do
    get new_token_transaction_url
    assert_redirected_to new_parent_session_path
  end

  test "unauthenticated request to create redirects to sign-in" do
    post token_transactions_url, params: { token_transaction: { child_id: @child_one.id, amount: 10, description: "Test" } }
    assert_redirected_to new_parent_session_path
  end

  test "unauthenticated request to show redirects to sign-in" do
    get token_transaction_url(@token_transaction)
    assert_redirected_to new_parent_session_path
  end

  # Happy path tests

  test "authenticated parent can view index" do
    sign_in @parent
    get token_transactions_url
    assert_response :success
  end

  test "authenticated parent can create token transaction for their own child" do
    sign_in @parent
    assert_difference("TokenTransaction.count") do
      post token_transactions_url, params: { token_transaction: { child_id: @child_one.id, amount: 10, description: "Bonus tokens" } }
    end
    assert_redirected_to token_transaction_url(TokenTransaction.last)
  end

  test "authenticated parent can view their own token transaction" do
    sign_in @parent
    get token_transaction_url(@token_transaction)
    assert_response :success
  end

  # Cross-parent isolation tests

  test "parent cannot create token transaction for another parent's child" do
    sign_in @parent_two
    assert_no_difference("TokenTransaction.count") do
      post token_transactions_url, params: { token_transaction: { child_id: @child_one.id, amount: 10, description: "Hacked tokens" } }
    end
    assert_redirected_to token_transactions_path
    assert_match /Invalid child/, flash[:alert]
  end

  test "parent cannot access another parent's token transaction" do
    sign_in @parent_two
    # token_transactions(:one) belongs to child_one which belongs to parent_one
    get token_transaction_url(@token_transaction)
    assert_response :not_found
  end

  test "index only shows current parent's transactions" do
    sign_in @parent
    get token_transactions_url
    assert_response :success
    # Verify that the response contains transaction for child_one
    # Create a token transaction for parent_two's child to ensure isolation
    other_parent_txn = parents(:two).children.first.token_transactions.create!(amount: 50, description: "Other parent's txn")
    get token_transactions_url
    # Parent one should not see parent two's transactions
    assert_select "body" do |body|
      assert_no_match /Other parent's txn/, body.to_s
    end
  end

  test "create rejects invalid child_id" do
    sign_in @parent
    assert_no_difference("TokenTransaction.count") do
      post token_transactions_url, params: { token_transaction: { child_id: 99999, amount: 10, description: "Invalid" } }
    end
    assert_redirected_to token_transactions_path
    assert_match /Invalid child/, flash[:alert]
  end
end
