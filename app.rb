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
        # omar()
        slim(:index)
    end
end

#Registrering
get('/register') do
    if session["user_id"] != nil
        flash[:already_logged_in] = "Du är redan inloggad!"
        redirect "/webshop"
    else
        slim(:"user/register")
    end
end

#Logga in
get('/login') do
    if session["user_id"] != nil
        flash[:already_logged_in] = "Du är redan inloggad!"
        redirect "/webshop"
    else
        slim(:"user/login")
    end
end

#Route för att komma till användarens eller andras profil
get('/user/:id/profile') do
    user_id = params[:id]
    get_user_inventory(user_id)
end

get('/uploaded_pictures/:type/:name') do
    File.read("uploaded_pictures/#{params[:type]}/#{params[:name]}")
end

#Webshop
get('/webshop') do
    get_all_cards()
end

#Visa 1 kort
get('/card/:id') do
    card_id = params[:id].to_i
    show_one_card(card_id)
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
        p stats = db.execute("SELECT stat1_id, stat2_id FROM card_stats_rel WHERE card_id = ?", id).first
        if card == nil
            flash[:error] = "Kortet med id #{id} finns inte"
            redirect "/webshop"
        else
            slim(:"/cards/edit", locals:{card:card, stats:stats})
        end
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
    # path för databasen att lägga in i tabell
    p club = "uploaded_pictures/clubs/#{params[:club][:filename]}"
    p face = "uploaded_pictures/faces/#{params[:player_face][:filename]}"
    
    # file_path för ruby att veta vart den ska skriva in filen
    # p club_path = "public/uploaded_pictures/clubs/#{params[:club][:filename]}"
    # p face_path = "public/uploaded_pictures/faces/#{params[:player_face][:filename]}"

    stat1 = params[:stat1]
    stat2 = params[:stat2]
    stat1_num = ""
    stat2_num = ""
    stats = {1 => "Snabbhet", 2 => "Skott", 3 => "Passningar", 4 => "Styrka", 5 => "Skicklighet", 6 => "Dribbling",7 => "Uthållighet"}
    i = 0
    j = 0

    p "#{stat1} blev konverterad till"
    while i < (stats.length + 1)
        if stats[i] == stat1
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

    create_card(name, position, club, face, rating, stat1, stat2, stat1_num, stat2_num, user_id)
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
    if position == nil
        update_card_without_position(card_id, name, rating)
    else
        update_card(card_id, name, rating, position)
    end
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