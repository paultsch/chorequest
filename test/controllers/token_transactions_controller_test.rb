require "test_helper"

class TokenTransactionsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @token_transaction = token_transactions(:one)
  end

  test "should get index" do
    get token_transactions_url
    assert_response :success
  end

  test "should get new" do
    get new_token_transaction_url
    assert_response :success
  end

  test "should create token_transaction" do
    assert_difference("TokenTransaction.count") do
      post token_transactions_url, params: { token_transaction: { amount: @token_transaction.amount, child_id: @token_transaction.child_id, description: @token_transaction.description } }
    end

    assert_redirected_to token_transaction_url(TokenTransaction.last)
  end

  test "should show token_transaction" do
    get token_transaction_url(@token_transaction)
    assert_response :success
  end

  test "should get edit" do
    get edit_token_transaction_url(@token_transaction)
    assert_response :success
  end

  test "should update token_transaction" do
    patch token_transaction_url(@token_transaction), params: { token_transaction: { amount: @token_transaction.amount, child_id: @token_transaction.child_id, description: @token_transaction.description } }
    assert_redirected_to token_transaction_url(@token_transaction)
  end

  test "should destroy token_transaction" do
    assert_difference("TokenTransaction.count", -1) do
      delete token_transaction_url(@token_transaction)
    end

    assert_redirected_to token_transactions_url
  end
end
