class AddRunnerGame < ActiveRecord::Migration[7.0]
  def up
    Game.reset_column_information
    Game.create!(name: 'Runner', description: 'Jungle Runner — jump over obstacles to score points!', token_per_minute: 1)
  rescue => e
    Rails.logger.warn "Could not create Runner game: "+e.message
  end

  def down
    Game.where(name: 'Runner').destroy_all
  end
end
