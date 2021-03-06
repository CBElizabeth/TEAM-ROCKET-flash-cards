get '/decks' do
  if logged_in?
    puts "[LOG] responding to a GET request for /decks"
    @decks = Deck.all
    erb :decks
  else
    redirect '/'
  end
end

# starts a round, asks for a guess
get '/round/:deck_id' do

  if logged_in?
    @front = true
    puts "[LOG] responding to a GET request for /round/deck_id"

    @deck = Deck.find(params[:deck_id])
    @round = Round.find_or_create_by(deck_id: @deck.id, user_id: session[:id])
    @round.deck_order = @deck.deck_shuffle.map { |card| card.id }.join(",")
    @round.save


    @current_index = @round.current_card_index || 0
    current_card(@current_index)

    erb :round
  else
    redirect '/'
  end
end

# checks entered guess right/wrong
post '/round/:deck_id/:index' do
  puts "[LOG] responding to a POST request for /round/deck_id/index"

  @front = false
  current_round

  @current_index = params[:index].to_i
  current_card(@current_index)
  @current_card.correct = @current_card.answer == params[:guess]
  @current_card.save

  erb :round
end

get '/round/:deck_id/finish' do
  if logged_in?
    current_round
    @legendary = @deck.cards.where(correct: true).count == @deck.cards.size
    erb :endgame
  else
    redirect '/'
  end
end


# clicks on next, goes to next card
get '/round/:deck_id/:index' do
  if logged_in?
    @front = true
    current_round

    @current_index = params[:index].to_i + 1

    if @current_index <= @deck.cards.size - 1
      current_card(@current_index)
    else
      redirect "/round/#{@deck.id}/finish"
    end
    erb :round
  else
    redirect '/'
  end
end



def current_round
  @deck = Deck.find(params[:deck_id])
  @round = Round.where(deck_id: @deck.id, user_id: session[:id]).first
end


def current_card(current_index)
  @current_card = Card.find(@round.deck_order.split(",")[current_index])
  @round.current_card_index = current_index
  @round.save
end