# README

This README would normally document whatever steps are necessary to get the
application up and running.

Things you may want to cover:

* Ruby version

* System dependencies

* Configuration

* Database creation

* Database initialization

* How to run the test suite

* Services (job queues, cache servers, search engines, etc.)

* Deployment instructions

* ...

Quick start (WSL / development):

1. Install gems and prepare DB:

```bash
cd ~/projects/chorequest
bundle install
rails db:create db:migrate db:seed
```

2. Start the server:

```bash
bin/rails server -b 0.0.0.0
```

3. Open http://localhost:3000 and use the seeded accounts:
- Parent admin: alice@example.com / password

Notes:
- Devise is included for parent authentication. After `bundle install`, run `rails generate devise:install` if you need to re-run generators.
- Add SSH keys and GitHub Actions separately if deploying.

