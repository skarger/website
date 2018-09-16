source 'https://rubygems.org'

# Bundle edge Rails instead: gem 'rails', github: 'rails/rails'
gem 'rails', '~> 5.2'
# Use postgres as the database for Active Record
gem 'pg'
# enable PostGIS
gem 'activerecord-postgis-adapter'
# Use SCSS for stylesheets
gem 'sass-rails'
# Use Uglifier as compressor for JavaScript assets
gem 'uglifier'

# Use CoffeeScript for .js.coffee assets and views
gem 'coffee-rails'

# Use jquery as the JavaScript library
gem 'jquery-rails'

gem 'webpacker'

# Turbolinks makes following links in your web application faster. Read more: https://github.com/rails/turbolinks
gem 'turbolinks'

# Spring speeds up development by keeping your application running in the background. Read more: https://github.com/rails/spring
gem 'spring',        group: :development

# Use ActiveModel has_secure_password
gem 'bcrypt'

# Use Capistrano for deployment
# gem 'capistrano-rails', group: :development

# Use debugger
# gem 'debugger', group: [:development, :test]

group 'production' do
  gem 'puma'
  gem 'rails_12factor'
  gem 'rack-timeout'
end

group :development, :test do
  gem 'rspec-rails'
  gem 'pry'
  gem 'rails-controller-testing'
end

group :development do
  gem 'listen'
end

group :test do
  gem 'json_expressions'
end

ruby '2.4.1'
