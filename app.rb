require 'bcrypt'
require 'sinatra'
require 'sinatra/flash'
require 'sinatra/reloader'
require 'slim'
require 'sqlite3'
require_relative './model.rb'
include Model
enable :sessions

#get routes

#Första sidan
get('/') do
    if session["logged_in"] == true
        redirect('/webshop')
    else
        slim(:index)
    end
end

#Registrering
get('/register') do
    if session["logged_in"] == true
        redirect "/webshop"
    else
        slim(:"user/register")
    end
end

#Logga in
get('/login') do
    if session["logged_in"] == true
        redirect "/webshop"
    else
        slim(:"user/login")
    end
end

#Route för att komma till användarens eller andras inventory
get('/inventory/:user') do
    user = params[:user]
    get_inventory(user)
end

#Webshop
get('/webshop') do
    get_all_cards()
end

get('/coins') do
    make_coins()
end

#Visa 1 kort
get('/card/:id') do
    card_id = params[:id].to_i
    show_one_card(card_id)
end

#Skapa kort
get('/cards/new') do
    new_card()
end

#Uppdatera kort
get('/cards/:id/edit') do
    card_id = params[:id].to_i
    edit_card(card_id)
end

#post-routes

#Registrering
post('/register') do
    username = params["username"]
    password = params["password"]
    password_conf = params["password_conf"]
    register_user(username, password, password_conf)
end

#Logga in
post('/login') do
    username = params["username"]
    password = params["password"]
    login_user(username, password)
end

#Skapa kort
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

post('/earn_coins') do
    coins = params[:amount].to_i
    earn_coins(coins)
end

#Köp kort
post('/cards/:id/buy') do
    card_id = params["id"].to_i
    buy_card(card_id)
end

#Uppdatera kort
post('/cards/:id/update') do
    card_id = params["id"].to_i
    name = params[:name]
    rating = params[:rating].to_i
    position = params[:position]
    update_card(card_id, name, rating, position)
end

#Radera kort
post('/cards/:id/delete') do
    card_id = params[:id].to_i
    delete_card(card_id)
end

#Logga ut
post('/logout') do
    session.destroy
    redirect('/')
end