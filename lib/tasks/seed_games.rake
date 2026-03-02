namespace :db do
  namespace :seed do
    desc "Seed games only — idempotent, safe to run on production without touching user data"
    task games: :environment do
      games = [
        { name: 'Pong',          description: 'Classic pong game',                                                            token_per_minute: 1 },
        { name: 'Berry Hunt',    description: "Count berries with Pyrch! A fun counting game for little learners aged 4–6.", token_per_minute: 1 },
        { name: 'Jungle Runner', description: 'Jump over obstacles in the jungle and rack up points!',                       token_per_minute: 1 },
      ]

      games.each do |attrs|
        game = Game.find_or_create_by!(name: attrs[:name]) do |g|
          g.description      = attrs[:description]
          g.token_per_minute = attrs[:token_per_minute]
        end
        puts "#{game.previously_new_record? ? '  Created' : '  Already exists'}: #{game.name}"
      end

      puts "Done. #{Game.count} game(s) total."
    end
  end
end
