class BountiesController < ApplicationController
  before_action :authenticate_coder!, only: [:update_or_create]

  respond_to :html, :coffee

  def index
    @issues = Issue.statted.where(closed_at: nil)
              .with_stats(:total_bounty_value)
              .includes(:repository, :unclaimed_bounties).run
  end

  def update_or_create
    issue_id = bounty_params[:issue_id]

    new_abs_value = bounty_params[:absolute_value]
    # Value must be a non-negative integer
    unless new_abs_value =~ /^\d+$/
      flash.now[:error] = 'This value is not an integer.'
      return
    end

    @issue = Issue.find issue_id

    begin
      Bounty.update_or_create(@issue, current_coder, new_abs_value.to_i)
    rescue => error
      flash.now[:error] = error.message
    end
  end

  private

  def bounty_params
    params.require(:bounty).permit(:issue_id, :absolute_value)
  end
end
