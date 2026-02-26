class TokenTransactionsController < ApplicationController
  before_action :set_token_transaction, only: %i[ show edit update destroy ]

  # GET /token_transactions or /token_transactions.json
  def index
    return redirect_to root_path, alert: 'Not authorized' unless current_parent

    per_page = 20
    page = params[:page].to_i > 0 ? params[:page].to_i : 1

    # Allowed sort columns
    allowed = { 'child' => 'parents.name', 'amount' => 'token_transactions.amount', 'description' => 'token_transactions.description', 'date' => 'token_transactions.created_at' }
    sort_param = params[:sort].presence || 'date'
    sort_col = allowed[sort_param] || allowed['date']
    dir = params[:direction] == 'desc' ? 'DESC' : 'ASC'

    # Transactions for this parent's children only
    @token_transactions = TokenTransaction.joins(child: :parent)
                                          .where(children: { parent_id: current_parent.id })
                                          .select('token_transactions.*')
                                          .order("#{sort_col} #{dir}")
                                          .offset((page - 1) * per_page)
                                          .limit(per_page)

    # For balance-after calculation, load all transactions for these children ordered by created_at
    all_for_children = TokenTransaction.where(child_id: current_parent.children.select(:id)).order(:child_id, :created_at, :id)
    @balance_after = {}
    all_for_children.group_by(&:child_id).each do |_child_id, txs|
      running = 0
      txs.each do |t|
        running += t.amount.to_i
        @balance_after[t.id] = running
      end
    end

    @page = page
    @per_page = per_page
    @total_count = TokenTransaction.joins(:child).where(children: { parent_id: current_parent.id }).count
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
      @token_transaction = TokenTransaction.joins(:child).where(children: { parent_id: current_parent.id }).find(params[:id])
    end

    # Only allow a list of trusted parameters through.
    def token_transaction_params
      params.require(:token_transaction).permit(:child_id, :amount, :description)
    end
end
