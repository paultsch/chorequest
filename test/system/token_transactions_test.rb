require "application_system_test_case"

class TokenTransactionsTest < ApplicationSystemTestCase
  setup do
    @token_transaction = token_transactions(:one)
  end

  test "visiting the index" do
    visit token_transactions_url
    assert_selector "h1", text: "Token transactions"
  end

  test "should create token transaction" do
    visit token_transactions_url
    click_on "New token transaction"

    fill_in "Amount", with: @token_transaction.amount
    fill_in "Child", with: @token_transaction.child_id
    fill_in "Description", with: @token_transaction.description
    click_on "Create Token transaction"

    assert_text "Token transaction was successfully created"
    click_on "Back"
  end

  test "should update Token transaction" do
    visit token_transaction_url(@token_transaction)
    click_on "Edit this token transaction", match: :first

    fill_in "Amount", with: @token_transaction.amount
    fill_in "Child", with: @token_transaction.child_id
    fill_in "Description", with: @token_transaction.description
    click_on "Update Token transaction"

    assert_text "Token transaction was successfully updated"
    click_on "Back"
  end

  test "should destroy Token transaction" do
    visit token_transaction_url(@token_transaction)
    click_on "Destroy this token transaction", match: :first

    assert_text "Token transaction was successfully destroyed"
  end
end
