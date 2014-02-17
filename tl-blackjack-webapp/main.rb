require 'rubygems'
require 'sinatra'
require 'sinatra/reloader'
require 'pry' # make sure that this is also included in the gem file

# run the following in the nitrous.io console shotgun -o 0.0.0.0 -p 3000 main.rb
set :sessions, true

BLACKJACK_AMOUNT = 21
DEALER_HIT_MIN = 17
INITIAL_POT_TOTAL = 500

# Define the helper methods
helpers do
 
  def calculate_total(cards) # [['Suit','Rank'],['Suit','Rank'],...]

	  arr = cards.map{ |e| e[1] }
	  total = 0

	  arr.each do |value|
	    if value == "A"
	      total += 11
	    elsif value.to_i == 0 # J, Q, K
	      total += 10
	    else
	      total += value.to_i
	    # else total += a.to_i == 0 ? 10 : a.to_i
	    end
	  end

	  # correct for Aces
	  arr.select{|e| e == "A"}.count.times do
	    total -= 10 if total > BLACKJACK_AMOUNT

	  end

	  return total
	end

	def card_image(card) # [ 'H' , '4' ]

	  pretty_suit = case card[0]
      when 'H' then 'hearts'
      when 'D' then 'diamonds'
      when 'S' then 'spades'
      when 'C' then 'clubs'
    end

    value = card[1]
    if ['J','Q','K','A'].include?(value)
    	value = case card[1]
	      when 'J' then 'jack'
	      when 'Q' then 'queen'
	      when 'K' then 'king'
	      when 'A' then 'ace'
	    end
    end

	  "<img src ='/images/cards/#{pretty_suit}_#{value}.jpg' class='card_image'>"

	end

	def winner!(msg)
		@winner = "<strong>#{session[:player_name]} wins!</strong> #{msg}"
		@show_hit_or_stay_buttons = false
		@show_play_again_button = true
    session[:player_pot] += session[:player_bet_amount] 
	end

	def loser!(msg)
		@loser = "<strong>#{session[:player_name]} loses!</strong> #{msg}"
		@show_hit_or_stay_buttons = false
		@show_play_again_button = true
    session[:player_pot] -= session[:player_bet_amount] 
	end

	def tie!(msg)
		@winner = "<strong>It's a tie!</strong> #{msg}"
		@show_play_again_button = true
	end

end

# this will run before all the actions below
before do 
	@show_hit_or_stay_buttons = true
	@show_dealer_hit_button = false
	@show_play_again_button = false
end

get '/' do
	
	if session[:player_name]
		redirect '/bet'
	else
		redirect '/new_player'
	end

end

get '/new_player' do
  session[:player_pot] = INITIAL_POT_TOTAL
  @first_round = true
	erb :new_player
end

post '/new_player' do
  #session hash (limit of 4KB)
  if params[:player_name].empty?
  	@error = "Name is required!"
  	halt erb :new_player
  end

  session[:player_name] = params[:player_name] #param's from url parameters, name of input in erb file

  redirect '/bet'
end

get '/bet' do
  
  session[:player_bet_amount] = nil

  if session[:player_name].empty?
    redirect '/new_player'
  end
  
  erb :bet
end

post '/bet' do

  if params[:player_bet_amount].nil?
    @error = "Bet amount must be a real number"
    #binding.pry
    halt erb :bet
  elsif params[:player_bet_amount].to_i <= 0
    @error = "Bet amount must be greater than 0"
    halt erb :bet
  elsif params[:player_bet_amount].to_i > session[:player_pot]
    @error = "Bet amount must be less than what you have in the pot. You currenly have $#{session[:player_pot]} in the pot."
    halt erb :bet
  else # happy path
    session[:player_bet_amount] = params[:player_bet_amount].to_i
    redirect '/game'
  end
end

get '/game' do
	
	# Need to set up initial game values and render template

	session[:turn] = session[:player_name]

	# Create a deck and put it in session
	suits = ['H', 'D', 'S', 'C']
	cards = ['2', '3', '3', '4', '5', '6', '7', '8', '9', '10','J','Q','K','A']
	session[:deck] = suits.product(cards).shuffle!
	session[:player_cards]  = []
	session[:dealer_cards]  = []
	
	2.times do 
		session[:player_cards] << session[:deck].pop
		session[:dealer_cards] << session[:deck].pop
	end

	player_total = calculate_total(session[:player_cards])
	if player_total == BLACKJACK_AMOUNT
		winner!("Congratulations! #{session[:player_name]} hit blackjack!")
	end

	erb :game
end

post '/game/player/hit' do

	# deal new cards
	session[:player_cards] << session[:deck].pop

	player_total = calculate_total(session[:player_cards])

	if player_total == BLACKJACK_AMOUNT
		winner!("#{session[:player_name]} hit blackjack!")		
	elsif player_total > BLACKJACK_AMOUNT
		loser!("Sorry, it looks like #{session[:player_name]} busted at #{player_total}")
	end

	# render the template but do not redirect
	erb :game, layout: false

end

post '/game/player/stay' do
	
	@success = "#{session[:player_name]} has chosen to stay."
	@show_hit_or_stay_buttons = false
	redirect '/game/dealer'
  
end

get '/game/dealer' do
	
	session[:turn] = "dealer"

	@show_hit_or_stay_buttons = false

	dealer_total = calculate_total(session[:dealer_cards])

	if dealer_total == BLACKJACK_AMOUNT
		loser!("Sorry, the dealer hit blackjack!")
	elsif dealer_total > BLACKJACK_AMOUNT
		winner!("Congratulations, dealer busted at #{dealer_total}! You win!")
	elsif dealer_total >= DEALER_HIT_MIN # 17, 18, 19, 20
		# dealer stays
		redirect '/game/compare'
	else
		# dealer hits
		@show_dealer_hit_button = true
	end

	erb :game, layout: false

end

get '/game/compare' do

	@show_hit_or_stay_buttons = false
	player_total = calculate_total(session[:player_cards])
	dealer_total = calculate_total(session[:dealer_cards])

	if player_total < dealer_total
			loser!("#{session[:player_name]} stayed at #{player_total}, and the dealer stayed at #{dealer_total}")
	elsif player_total > dealer_total
			winner!("#{session[:player_name]} stayed at #{player_total}, and the dealer stayed at #{dealer_total}")
	else
		tie!("Both #{session[:player_name]} and the dealer stayed at #{dealer_total}")
	end

	erb :game, layout: false

end

post '/game/dealer/hit' do	
	session[:dealer_cards] << session[:deck].pop
	redirect '/game/dealer'
end

get '/game_over' do
	erb :game_over
end

