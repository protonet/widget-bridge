source :rubygems

gem 'sinatra'
gem 'thin'
gem 'data_mapper'
gem 'sinatra-jsonp', :require => 'sinatra/jsonp'

group :development, :test do
  gem 'dm-sqlite-adapter'
  gem 'sqlite3'
  gem 'shotgun'
end

group :production do
  gem 'dm-postgres-adapter'
  gem 'pg'
  gem 'do_postgres'
end