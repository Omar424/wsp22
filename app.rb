require 'bcrypt'
require 'sinatra'
require 'sinatra/flash'
require 'sinatra/reloader'
require 'slim'
require 'sqlite3'
require_relative './model.rb'
include Model
enable :sessions

# Displays homepage
get('/') do
    if session["logged_in"] == true
        redirect('/webshop')
    else
        slim(:index)
    end
end

# Display reigster page
get('/register') do
    if session["logged_in"] == true
        redirect "/webshop"
    else
        slim(:"user/register")
    end
end

def register_help(data, username, password)
    if data == 0
        flash[:username_exist] = "Användarnamnet är upptaget!"
        redirect "/register"
    elsif data == 0.5
        flash[:wrong_confirm] = "Lösenorden matchar inte!"
        redirect "/register"
    elsif data == 1
        hashed_password = BCrypt::Password.create(password)
        create_user(username, hashed_password)
    end
end

# Display login page
get('/login') do
    if session["logged_in"] == true
        redirect "/webshop"
    else
        slim(:"user/login")
    end
end

def login_help(data, user)
    if data == 0
        flash[:no_such_user] = "Användaren finns inte!"
        redirect "/login"
    elsif data == 0.5
        flash[:wrong_pass] = "Fel lösenord!"
        redirect "/login"
    elsif data == 1
        session[:logged_in] = true
        session[:username] = user["username"]
        session[:role] = user["role"]
        session[:coins] = user["coins"]
        redirect "/webshop"
    end
end

# Shows users inventory
# @param [String] :user, username
#
# @see Model.get_inventory
get('/inventory/:user') do
    user = params[:user]
    if session[:logged_in] == true
        get_inventory(user)
    else
        flash[:error] = "You need to be logged in to view inventory"
        redirect '/login'
    end
end

def inventory_help(data, user, user_data, user_cards, first_stats, second_stats)
    if data == true
        slim(:"inventory", locals:{user:user_data, cards:user_cards, stat1:first_stats, stat2:second_stats})
    elsif data == false
        flash[:error] = "Användaren #{user} finns inte"
        redirect "/webshop"
    end
end

# Displays the webshop
#
# @see Model.get_all_cards
get('/webshop') do
    username = session[:username]
    get_all_cards(username)
end

def display_webshop(cards, first_stats, second_stats, coins)
    slim(:webshop, locals:{cards:cards, stat1:first_stats, stat2:second_stats, coins:coins})
end

# Attempts to display form to add coins to a user
#
get('/coins') do
    if session[:logged_in] == true
        slim(:coins)
    else
        flash[:error] = "Du måste logga in för att komma åt sidan"
        redirect "/"
    end
end

# Displays a specific card
#
# @param [Integer] :id, id of the card
# @see Model.show_one_card
get('/card/:id') do
    card_id = params[:id].to_i
    show_one_card(card_id)
end

def show_help(data, card, card_id, card_stats)
    if data == true
        first_stats = []
        second_stats = []
        first_stats << card_stats["stat1_id"]
        second_stats << card_stats["stat2_id"]
        convert_to_statname(first_stats)
        convert_to_statname(second_stats)
        slim(:"/cards/show", locals:{card:card, stat1:first_stats, stat2:second_stats})
    else
        flash[:error] = "Kortet med id #{card_id} finns inte"
        redirect "/webshop"
    end
end

# Displays form for making a card
#
# @see Model.create_card
get('/cards/new') do
    if session["logged_in"] == true
        new_card()
    else
        flash[:error] = "You need to be logged in to create a card"
        redirect "/"
    end
end

def new_card_help(stats)
    slim(:"cards/new", :locals => {stats: stats})
end

# Displays form for editing a card
#
# @param [Integer] :id, id of the card
get('/cards/:id/edit') do
    if session["logged_in"] == true
        card_id = params[:id].to_i
        username = session[:username]
        edit_card(card_id, username)
    else
        flash[:error] = "Logga in för att redigera ett kort"
        redirect "/"
    end
end

def edit_help(card, first_stats, second_stats, card_id, data, user_owns)
    if user_owns == true
        slim(:"/cards/edit", locals:{card:card, stat1:first_stats, stat2:second_stats})
    elsif user_owns == false
        flash[:error] = "Du kan inte redigera ett kort du inte äger"
        redirect "/webshop"
    elsif data == false
        flash[:error] = "Kortet med id #{card_id} finns inte"
        redirect "/webshop"
    end
end

# Attempts to register new user and redirect to login page
#
# @param [String] username, username
# @param [String] password, password
# @param [String] password_conf, password-conf, password confirmation
#
# @see Model.register_user
post('/register') do
    username = params["username"]
    password = params["password"]
    password_conf = params["password_conf"]
    register_user(username, password, password_conf)
end

# Attempts to login user and redirect to webshop
#
# @param [String] username, username
# @param [String] password, password
#
# @see Model.login_user
post('/login') do
    username = params["username"]
    password = params["password"]
    login_user(username, password)
end

# Attempts to create a new card and redirect to webshop
#
# @see Model.create_card
post('/create_card') do
    if session["logged_in"] == true
        owner = session[:username]
        name = params[:name]
        position = params[:position]
        rating = params[:rating]
        price = params[:price]
        club = "uploaded_pictures/clubs/#{params[:club][:filename]}"
        face = "uploaded_pictures/faces/#{params[:player_face][:filename]}"
        club_path = params[:club][:tempfile]
        face_path = params[:player_face][:tempfile]
        
        stat1 = params[:stat1]
        stat2 = params[:stat2]
        stats = {1 => "Snabb", 2 => "Bra skott", 3 => "Bra passningar", 4 => "Stark", 5 => "Skicklig", 6 => "Bra dribbling",7 => "Bra uthållighet"}
        i = 0
        j = 0

        p "#{stat1} blev konverterad till"
        while i < (stats.length + 1)
            if  stat1 == stats[i]
                stat1_num = i.to_i
            end
            i += 1
        end
        p "#{stat1_num}"

        p "#{stat2} blev konverterad till"
        while j < (stats.length + 1)
            if stats[j] == stat2
                stat2_num = j.to_i
            end
            j += 1
        end
        p "#{stat2_num}"

        create_card(name, position, club, club_path, face, face_path, rating, stat1, stat2, stat1_num, stat2_num, owner, price)
    else
        flash[:error] = "Logga in för att skapa ett kort"
        redirect "/"
    end
end

# Attempts to add coins to user account and redirect to webshop
#
# @see Model.earn_coins
post('/earn_coins') do
    coins = params[:amount].to_i
    username = session[:username]
    earn_coins(coins, username)
end

# Attempt to buy a card and redirect to webshop
#
# @param [Integer] :id, id of the card
#
# @see Model.buy_card
post('/cards/:id/buy') do
    card_id = params["id"].to_i
    username = session[:username]
    buy_card(card_id, username)
end

# Attempt to edit a card and redirect to webshop
#
# @param [Integer] :id, id of the card
#
# @see Model.update_card
post('/cards/:id/update') do
    if session[:logged_in] == true
        card_id = params["id"].to_i
        name = params[:name]
        rating = params[:rating].to_i
        position = params[:position]
        update_card(card_id, name, rating, position)
    else
        flash[:error] = "Logga in för att komma åt sidan"
        redirect "/"
    end
end

# Attempt to delete a card and redirect to webshop
#
# @param [Integer] :id, id of the card
#
# @see Model.delete_card
post('/cards/:id/delete') do
    if session["logged_in"] == true
        card_id = params[:id].to_i
        username = session[:username]
        delete_card(card_id, username)
    else
        flash[:error] = "Du måste logga in för att komma åt sidan"
        redirect "/"
    end
end

# Attempts to logout user and redirect to homepage
post('/logout') do
    session.destroy
    redirect('/')
end