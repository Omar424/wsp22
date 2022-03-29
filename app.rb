require 'sinatra'
require 'sinatra/reloader'
require 'slim'
require 'sqlite3'
require 'bcrypt'
require_relative './model.rb'
enable :sessions

#get routes

#Första sidan
get('/') do
    if session["user_id"] != nil
        redirect('/webshop')
    else
        slim(:index)
    end
end

#Registrering
get('/register') do
    return slim(:"user/register", locals: { error: "" })
end

#Logga in
get('/login') do
    slim(:"user/login", locals: { error: "", sucess: "" })
end

#Error
get('/error') do
    slim(:error)
end

#Route för att komma till användarens eller andras profil
get('/user/:id/profile') do
    user_id = params[:id]

    if session["user_id"] != nil
        db = connect_to_db('db/db.db')
        user_data = db.execute("SELECT * FROM users where id = ?", user_id).first
        user_cards = db.execute("SELECT * FROM cards where user_id = ?", user_id)
    
        if user_data == nil
            "user with id: #{user_id} does not exist"
        elsif user_cards.length == 0
            slim(:"user/index", locals:{user_info:user_data, cards:user_cards, message: "user with id #{user_id} hasn't created a card"})
        else
            slim(:"user/index", locals:{user_info:user_data, cards:user_cards, message: "temp"})
        end
    else
        route = "/user/#{user_id}/profile"
        slim(:"/error", locals:{m:"Du måste vara inloggad för att se routen #{route}"})
    end
end

get('/uploaded_pictures/:type/:name') do
    File.read("uploaded_pictures/#{params[:type]}/#{params[:name]}")
end

#Inventory, användarens kort
get('/inventory') do
    
    if session["user_id"] != nil
        db = connect_to_db("db/db.db")
        cards = db.execute("SELECT * FROM cards WHERE user_id = ?", [session["user_id"]])
        stats = db.execute("SELECT * FROM stat")
        slim(:"inventory", locals: {cards:cards, stats:stats})
    else
        redirect('/')
    end
    
    # inventory()
end

#Webshop
get('/webshop') do
    get_all_cards()
end

#Visa 1 kort
get('/card/:id') do
    card_id = params[:id].to_i

    if session["user_id"] != nil
        db = connect_to_db("db/db.db")
        card_data = db.execute("SELECT * FROM cards WHERE id = ?", card_id).first

        if card_data != nil
            slim(:"cards/show", locals:{card:card_data, id:card_id})
        else
            "Card with id: #{card_id} does not exist :/"
        end
    else
        route = "/cards/#{card_id}"
        "Du måste logga in för att komma till routen #{route}"
    end
end

#Skapa kort
get('/cards/new') do
    if session["user_id"] != nil
        slim(:"cards/new", locals:{session_id: session["user_id"]})
    else
        route = "/cards/new"
        "Du måste logga in för att komma till routen #{route}"
    end
end

#Uppdatera kort
get('/cards/:id/edit') do
    if session[:user_id] != nil
        id = params[:id].to_i
        db = connect_to_db('db/db.db')
        card = db.execute("SELECT * FROM cards WHERE id = ?", id).first
        slim(:"/cards/edit", locals:{card:card})
    else
        "Du måste logga in för att redigera ett kort"
    end
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
    name = params[:name]
    position = params[:position]
    rating = params[:rating]
    stat1 = params[:stat1]
    stat2 = params[:stat2]
    stat3 = params[:stat3]
    # file_path för ruby att veta vart den ska skriva in filen
    p file_face_path = "public/uploaded_pictures/faces/#{params[:player_face][:filename]}"
    p file_club_path = "public/uploaded_pictures/clubs/#{params[:club][:filename]}"
    # path för get_routen att veta source för bilden
    p face_path = "uploaded_pictures/faces/#{params[:player_face][:filename]}"
    p club_path = "uploaded_pictures/clubs/#{params[:club][:filename]}"
    create_card(name, position, club_path, face_path, rating, stat1, stat2, stat3, session[:user_id])
end

#Köpa kort
post('/cards/:id/buy') do
    card_id = params["id"].to_i
    buy_card(card_id)
end

#Uppdatera kort
post('/cards/:id/update') do
    card_id = params[:id].to_i
    name = params[:name]
    rating = params[:rating].to_i
    position = params[:position]
    update_card(card_id, name, rating, position)
end

#Radera kort
post('/cards/:id/delete') do
    card_id = params["id"].to_i
    delete_card(card_id)
end

#Logga ut
post('/logout') do
    session.destroy
    redirect('/')
end

# before do
#     p "Before KÖRS, session_user_id är #{session[:user_id]}."

#     if (session[:user_id] ==  nil) && (request.path_info != '/')
#         session[:error] = "You need to log in to see this"
#         redirect('/error')
#     end
# end