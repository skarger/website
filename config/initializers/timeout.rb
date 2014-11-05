# config/initializers/timeout.rb
# originally copied from https://devcenter.heroku.com/articles/rails-unicorn
if Rails.env.production?
  Rack::Timeout.timeout = 10  # seconds
end
