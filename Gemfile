source :rubygems

gem 'sinatra'
gem 'thin'
gem 'data_mapper'
gem 'shotgun'
gem 'sinatra-jsonp', :require => 'sinatra/jsonp'

group :development, :test do
  gem 'dm-sqlite-adapter'
  gem 'sqlite3'
end

group :production do
  gem 'dm-postgres-adapter'
end