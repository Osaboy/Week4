arequire 'rubygems'
require 'sinatra'
require 'pry' # make sure that this is also included in the gem file

# set :sessions, true
# run the following in the nitrous.io console shotgun -o 0.0.0.0 -p 3000 main.rb

# from www.chasepursley.com
# set port for compatibility with nitrous.io

configure :development do
  set :bind, '0.0.0.0'
  set :port, 3000
end

get '/' do
  "Hello World! Christian Rocks! Uche is Awesome!"
end

get '/test' do
  #binding pry
  "From testing action!" + params[:some].to_s + params[:test]
end

get '/inline' do
  "Hello, directly from the action \'inline\'"
end

get '/template' do
  erb :mytemplate
end

get '/nested_template' do
  erb :"/users/profile" #same as erb :"/users/profile", because we didn't specify a default, it will be layout.erb
end

get '/nothere' do
  redirect '/inline'
end




