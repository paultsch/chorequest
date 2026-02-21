class TokenTransactionsController < ApplicationController
  before_action :set_token_transaction, only: %i[ show edit update destroy ]

  # GET /token_transactions or /token_transactions.json
  def index
    @token_transactions = TokenTransaction.all
  end

  # GET /token_transactions/1 or /token_transactions/1.json
  def show
  end

  # GET /token_transactions/new
  def new
    @token_transaction = TokenTransaction.new
  end

  # GET /token_transactions/1/edit
  def edit
  end

  # POST /token_transactions or /token_transactions.json
  def create
    @token_transaction = TokenTransaction.new(token_transaction_params)

    respond_to do |format|
      if @token_transaction.save
        format.html { redirect_to @token_transaction, notice: "Token transaction was successfully created." }
        format.json { render :show, status: :created, location: @token_transaction }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @token_transaction.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /token_transactions/1 or /token_transactions/1.json
  def update
    respond_to do |format|
      if @token_transaction.update(token_transaction_params)
        format.html { redirect_to @token_transaction, notice: "Token transaction was successfully updated.", status: :see_other }
        format.json { render :show, status: :ok, location: @token_transaction }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @token_transaction.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /token_transactions/1 or /token_transactions/1.json
  def destroy
    @token_transaction.destroy!

    respond_to do |format|
      format.html { redirect_to token_transactions_path, notice: "Token transaction was successfully destroyed.", status: :see_other }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_token_transaction
      @token_transaction = TokenTransaction.find(params[:id])
    end

    # Only allow a list of trusted parameters through.
    def token_transaction_params
      params.require(:token_transaction).permit(:child_id, :amount, :description)
    end
end
