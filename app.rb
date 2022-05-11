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

# Display login page
get('/login') do
    if session["logged_in"] == true
        redirect "/webshop"
    else
        slim(:"user/login")
    end
end

# Shows users inventory
# @param [String] :user, username
#
# @see Model.get_inventory
get('/inventory/:user') do
    user = params[:user]
    get_inventory(user)
end

# Displays the webshop
#
# @see Model.get_all_cards
get('/webshop') do
    get_all_cards()
end

# Displays form for making coins
#
# @see Model.make_coins
get('/coins') do
    make_coins()
end

# Displays a specific card
#
# @param [Integer] :id, id of the card
# @see Model.show_one_card
get('/card/:id') do
    card_id = params[:id].to_i
    show_one_card(card_id)
end

# Displays form for making a card
#
# @see Model.create_card
get('/cards/new') do
    new_card()
end

# Displays form for editing a card
#
# @param [Integer] :id, id of the card
get('/cards/:id/edit') do
    card_id = params[:id].to_i
    edit_card(card_id)
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

        create_card(name, position, club, face, rating, stat1, stat2, stat1_num, stat2_num, owner, price)
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
    earn_coins(coins)
end

# Attempt to buy a card and redirect to webshop
#
# @param [Integer] :id, id of the card
#
# @see Model.buy_card
post('/cards/:id/buy') do
    card_id = params["id"].to_i
    buy_card(card_id)
end

# Attempt to edit a card and redirect to webshop
#
# @param [Integer] :id, id of the card
#
# @see Model.update_card
post('/cards/:id/update') do
    card_id = params["id"].to_i
    name = params[:name]
    rating = params[:rating].to_i
    position = params[:position]
    update_card(card_id, name, rating, position)
end

# Attempt to delete a card and redirect to webshop
#
# @param [Integer] :id, id of the card
#
# @see Model.delete_card
post('/cards/:id/delete') do
    card_id = params[:id].to_i
    delete_card(card_id)
end

# Attempts to logout user and redirect to homepage
post('/logout') do
    session.destroy
    redirect('/')
end