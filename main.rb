require 'rubygems'
require 'sinatra'
require 'pry'

set :sessions, true

BLACKJACK_AMOUNT = 21
DEALER_MIN_HIT = 17
INITIAL_POT_AMOUNT = 500

helpers do
  def calculate_total(cards) # cards is [["H", "3"], ["D", "J"], ... ]
    arr = []
    cards.each { |card| arr << card }
    total = 0
    arr.each do |value|
      value = value.split[0...1].join(' ')
      if value == "Ace"
        total += 11
      if total > 21
        total = total -10
      end
      elsif value.to_i == 0 # J, Q, K
        total += 10
      else
        total += value.to_i
      end
    end
       total
  end

  def print_images(card) # ['H', '4']
    value2 = ''
    value = card.split[0...1].join('')
    value1 = card.split[1..1].join('')
    value1=value1[0]
    if value != '10'
      value = value[0]
      value = value.downcase
    end
    "<img src='/images/Cards/#{value1}#{value}.png' alt=#{value1}#{value}>"
  end
  def comparescores(player_scores,dealer_scores,stay='')
    session[:winorlose] = ''
    if player_scores == 21
      session[:winorlose] = 'win'
      return "Player hits blackjack. Player wins"
    end
    if dealer_scores == 21 and dealer_scores > player_scores && stay == 'stay'
      session[:winorlose] = 'lose'
      return "Dealer hits blackjack. Dealer wins"
    end
    if player_scores > 21
      session[:winorlose] = 'lose'
      return "You busted. You lost!"
    end
    if dealer_scores > 21
      session[:winorlose] = 'win'
      return "Dealer busted. you won!"
    end
    if dealer_scores == player_scores && stay == 'stay'
      session[:winorlose] = 'tie'
      return "Its a tie!"
    end
    if dealer_scores > player_scores && stay == 'stay'
      session[:winorlose] = 'lose'
      return "Dealer wins"
    end
    if dealer_scores < player_scores && stay == 'stay'
       session[:winorlose] = 'win'
       return " Player wins"
     end
     ''
   end
   def update_money
     if session[:winorlose] == 'win'
       session[:player_pot] = session[:player_pot] + session[:player_bet]
     elsif session[:winorlose] == 'lose'
       session[:player_pot] = session[:player_pot] - session[:player_bet]
     else
       session[:player_pot] = session[:player_pot]
     end
     "#{session[:player_name]} bet #{session[:player_bet]}. #{session[:player_name]} has #{ session[:player_pot]} left"
   end
end

before do
  @show_hit_or_stay_buttons = true
@initial = false
end

get '/' do
  if session[:player_name]
    redirect '/game'
  else
    redirect '/new_player'
  end
end

get '/new_player' do
  session[:player_pot] = INITIAL_POT_AMOUNT
  erb :new_player
end

post '/restart' do
  session[:player_name] = false
  redirect '/'
end

post '/new_player' do

  if params[:player_name].empty?
    @error = "Name is required"
    halt erb(:new_player)
  end

  session[:player_name] = params[:player_name]
  redirect '/bet'
end

get '/bet' do
  session[:player_bet] = nil
  erb :bet
end

post '/bet' do
  if params[:bet_amount].nil? || params[:bet_amount].to_i == 0
    @error = "Must make a bet."
    halt erb(:bet)
  elsif params[:bet_amount].to_i > session[:player_pot]
    @error = "Bet amount cannot be greater than what you have ($#{session[:player_pot]})"
    halt erb(:bet)
  else #happy path
    session[:player_bet] = params[:bet_amount].to_i
    redirect '/game'
  end
end

get '/game' do
    @initial = true
    card_number=['2','3','4','5','6','7','8','9','10','Jack','Queen','King','Ace']
    card_type=['spade','heart','club','diamond']
    cards=[]
    card_number.each do |x|
      card_type.each do |x1|
        cards << x + " " + x1
      end
    end
    cards = cards.shuffle!
    session[:player_cards] = []
    session[:computer_cards] = []
    session[:computer_total_scores] = 0
    session[:_total_scores] = 0
    session[:player_cards2] = [2,3,4,5,6,7,8]
    session[:player_cards] << cards.pop
    session[:player_cards] << cards.pop
    session[:computer_cards] << cards.pop
    session[:computer_cards] << cards.pop
    session[:deck] = cards
    session[:player_total_scores]  = calculate_total(session[:player_cards])
    session[:computer_total_scores]  = calculate_total(session[:computer_cards])
    erb :game
end

before do
@button_visible = true
@initial = false
session[:stay] = ''
end

post '/game/player/hit' do
  session[:player_cards] << session[:deck].pop

  session[:player_total_scores] = calculate_total(session[:player_cards])
  @initial = true

  erb :game, layout: false
end

post '/game/player/stay' do
   redirect '/game/dealer'
end

get '/game/dealer' do
  # decision tree
  session[:stay] = 'stay'
  dealer_total = calculate_total(session[:computer_cards])
  while session[:computer_total_scores] < 17
    session[:computer_cards] << session[:deck].pop
    session[:computer_total_scores] = calculate_total(session[:computer_cards])
  end
  @initial = false
  erb :game, layout: false
end

get '/game/compare' do
  player_total = calculate_total(session[:player_cards])
  dealer_total = calculate_total(session[:dealer_cards])
  if player_total < dealer_total
    loser!("#{session[:player_name]} stayed at #{player_total}, and the dealer stayed at #{dealer_total}.")
  elsif player_total > dealer_total
    winner!("#{session[:player_name]} stayed at #{player_total}, and the dealer stayed at #{dealer_total}.")
  else
    tie!("Both #{session[:player_name]} and the dealer stayed at #{player_total}.")
  end

  erb :game, layout: false
end
