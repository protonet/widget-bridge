require 'sinatra'
require 'data_mapper'
require 'net/http'
require 'net/https'
require 'uri'
require 'json'
require "sinatra/jsonp"

class LiveUser
  include DataMapper::Resource  
  property :id,           Serial
  property :login,        String
  property :password,     String
  property :user_id,      Integer, :key => false
  property :channel_id,   Integer, :key => false
  property :communication_token,  String
  property :communication_token_expires_at, Date
  property :created_at,   Date
end

configure do
  
  DataMapper.setup(:default, (ENV["DATABASE_URL"] || "sqlite3:///#{Dir.pwd}/development.sqlite3"))
  DataMapper.auto_upgrade!
  
  set :api_url, (ENV['API_URL'] || "http://localhost:3000")
  set :api_user, (ENV['API_USER'] || "admin")
  set :api_pw, (ENV['API_PW'] || "admin")
  if ENV['ADMIN_USERS']
    set :admin_ids, ENV['ADMIN_USERS'].split(",") 
  else
    set :admin_ids, [1]
  end

  enable :logging, :dump_errors, :raise_errors
end


get '/' do
  "Hello, world"
end

def fetch_api(path, options = nil)
  url = URI.parse(settings.api_url)
  if options
    req = Net::HTTP::Post.new(path)
    req.set_form_data(options)
  else
    req = Net::HTTP::Get.new(path)
  end
  req.basic_auth settings.api_user, settings.api_pw
  sock = Net::HTTP.new(url.host, url.port)
  sock.use_ssl = true if url.instance_of?(URI::HTTPS)
  res = sock.start do |http| 
    http.request(req)
  end
  
  if res.code.to_i <  400
    return JSON.parse(res.body) rescue true
  else
    return false
  end
end

get '/update/:id' do
  @user = LiveUser.first(:user_id => params[:id].to_i)
  user = fetch_api("/api/v1/users/#{@user.user_id}")
  @user.update(
    :communication_token => user["communication_token"],
    :communication_token_expires_at => user["communication_token_expires_at"],
    :created_at => Date.today
  )
  JSONP [{ 
    :user_id => @user.user_id, 
    :channel_id => @user.channel_id, 
    :communication_token => @user.communication_token,
    :communication_token_expires_at => @user.communication_token_expires_at,
    :created_at => @user.created_at
  }]
end

get '/start' do
    
  @user = LiveUser.create(
    :login => "live-user#{LiveUser.count}",
    :password => rand(36**8).to_s(36),
    :created_at => Date.today
  )
  
  # create user
  user = fetch_api("/api/v1/users", {
    :login => @user.login, 
    :password => @user.password, 
    :email => "#{@user.login}@example.com",
    :no_channels => true
  })

  if user
    @user.update(:user_id => user["user_id"])
  else
    return "could not create a user"
  end
  
  # get communication_token
  user = fetch_api("/api/v1/users/#{@user.user_id}")

  if user
    @user.update(
      :communication_token => user["communication_token"],
      :communication_token_expires_at => user["communication_token_expires_at"]
    )
  else
    return "could not fetch a user"
  end
  
  # create channel
  channel = fetch_api("/api/v1/channels", {'name' => @user.login})
  if channel
    @user.update(:channel_id => channel["channel_id"])
  else
    return "could not create a channel"
  end

  # create listen
  fetch_api("/api/v1/listens", {'user_id' => @user.user_id, 'channel_id' => @user.channel_id})
  settings.admin_ids.each do |admin_id|
    fetch_api("/api/v1/listens", {'user_id' => admin_id, 'channel_id' => @user.channel_id})
  end
  
  # create a user + channel
  # return json with user_credentials + channel_id + SocketUrl
  JSONP [{ 
    :user_id => @user.user_id, 
    :channel_id => @user.channel_id, 
    :communication_token => @user.communication_token,
    :created_at => @user.created_at,
    :communication_token_expires_at => @user.communication_token_expires_at
  }]
  
end

get '/cleanup' do
  @users = LiveUser.all(:created_at.lt => Date.today - 7)
  @users.each do |user|
    fetch_api("/api/v1/channels/#{user.channel_id}", {'_method' => :delete })
    fetch_api("/api/v1/user/#{user.user_id}", {'_method' => :delete })
    user.destroy
  end
  JSONP "OK"
end