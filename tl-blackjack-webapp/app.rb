# Simple site that has an index page, about page and contact page
# uses haml for the template

require 'rubygems'
require 'sinatra'
require 'haml'

configure :development do
  set :bind, '0.0.0.0'
  set :port, 3000
end

get '/' do
  @title = "Home Page"
  haml :index
end

get '/about' do
  @title = "About Us"
  haml :about
end

get '/contact' do
  @title = "Contact Us"
  haml :contact
end

