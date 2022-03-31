require 'sinatra'
require 'sinatra/reloader'
require 'slim'
require 'sqlite3'
require 'bcrypt'
require 'sinatra/flash'
require_relative './model.rb'
enable :sessions

#get routes

#Första sidan
get('/') do
    if session["user_id"] != nil
        redirect('/webshop')
    else
        # determine_stat("Snabbhet")
        # determine_stat("Uthållighet")
        # determine_stat("Skott")
        # convert_stats()
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
            flash[:error] = "Användare med id #{user_id} finns inte"
            redirect "/"
        elsif user_cards.length == 0
            slim(:"user/index", locals:{user_info:user_data, cards:user_cards, message: "user with id #{user_id} hasn't created a card"})
        else
            slim(:"user/index", locals:{user_info:user_data, cards:user_cards, message: "temp"})
        end
    else
        flash[:error] = "Du måste vara inloggad för att se en profil"
        redirect "/"
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
        flash[:error] = "Logga in för att visa ett kort"
        redirect "/"
    end
end

#Skapa kort
get('/cards/new') do
    if session["user_id"] != nil
        db = connect_to_db("db/db.db")
        stats = db.execute("SELECT stats from stat")
        slim(:"cards/new", locals:{session_id: session["user_id"], stats:stats})
    else
        flash[:error] = "Logga in för att skapa ett kort"
        redirect "/"
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
        flash[:error] = "Logga in för att redigera ett kort"
        redirect "/"
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
    user_id = session[:user_id]
    
    # file_path för ruby att veta vart den ska skriva in filen
    # p club_path = "public/uploaded_pictures/clubs/#{params[:club][:filename]}"
    # p face_path = "public/uploaded_pictures/faces/#{params[:player_face][:filename]}"
    
    # path för databasen att lägga in i tabell
    p club = "uploaded_pictures/clubs/#{params[:club][:filename]}"
    p face = "uploaded_pictures/faces/#{params[:player_face][:filename]}"

    stat1 = params[:stat1]
    stat2 = params[:stat2]
    stat3 = params[:stat3]

    stats = {1 => "Snabbhet", 2 => "Skott", 3 => "Passningar", 4 => "Styrka", 5 => "Skicklighet", 6 => "Dribbling",7 => "Uthållighet"}
    
    p "#{stat1} blev konverterad till"
    i = 0
    while i < (stats.length + 1)
        if stats[i] == stat1
            stat1 = i.to_i
        end
        i += 1
    end
    p "#{stat1}"

    p "#{stat2} blev konverterad till"
    j = 0
    while j < (stats.length + 1)
        if stats[j] == stat2
            stat2 = j.to_i
        end
        j += 1
    end
    p "#{stat2}"
    
    p "#{stat3} blev konverterad till"
    k = 0
    while k < (stats.length + 1)
        if stats[k] == stat3
            stat3 = k.to_i
        end
        k += 1
    end
    p "#{stat3}"

    create_card(name, position, club, face, rating, stat1, stat2, stat3, user_id)
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