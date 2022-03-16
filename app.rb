require 'sinatra'
require 'sinatra/reloader'
require 'slim'
require 'sqlite3'
require 'bcrypt'
require_relative './model.rb'
enable :sessions

#get routes


get('/') do
    if session["user_id"] != nil
        redirect('/webshop')
    else
        slim(:index)
    end
end

get('/register') do
    return slim(:"user/register", locals: { error: "" })
end

get('/login') do
    slim(:"user/login", locals: { error: "", sucess: "" })
end

get('/logout') do
    session.destroy
    redirect("/")
end

get('/error') do
    slim(:error)
end

get('/uploaded_pictures/:type/:name') do
    File.read("uploaded_pictures/#{params[:type]}/#{params[:name]}")
end

get('/inventory') do

    if session["user_id"] != nil
        db = connect_to_db("db/db.db")
        inventory = db.execute("SELECT * FROM cards WHERE user_id = ?", [session["user_id"]])
        inventory = db.execute("SELECT * FROM stats WHERE user_id = ?", [session["user_id"]])
        slim(:"inventory", locals: { inventory: inventory })
    else
        redirect('/')
    end

    # get_cards()

end

get('/webshop') do
    get_all_cards()
end

get('/card/:id') do
    db = db_connection('db/db.db')
    card_id = params[:id]

    card_data = db.execute("SELECT * FROM cards WHERE id= ?", card_id).first

    if card_data.nil?
        session[:message] = "card does not exist"
        redirect('/error')
    end

    slim(:"cards/index", locals:{card_info:card_data})
end

#Man ska inte komma till denna routen utan att vara inloggad, session_id ska vara tillgängligt
get('/cards/new') do
    slim(:"cards/new", locals:{session_id: session["user_id"]})
end

#post routes

post('/register') do
    username = params["username"]
    password = params["password"]
    password_conf = params["password_conf"]
    register_user(username, password, password_conf)
end

post('/login') do
    username = params["username"]
    password = params["password"]
    login_user(username, password)
end

#Man ska inte komma till denna routen utan att vara inloggad, session_id ska vara tillgängligt
post('/create_card') do

    name = params[:name]
    position = params[:position]
    rating = params[:rating]
    stat1 = params[:stat1]
    stat2 = params[:stat2]
    stat3 = params[:stat3]
    p session[:user_id]
    # file_path för ruby att veta vart den ska skriva in filen
    p file_face_path = "public/uploaded_pictures/faces/#{params[:player_face][:filename]}"
    p file_club_path = "public/uploaded_pictures/clubs/#{params[:club][:filename]}"
    # path för get_routen att veta source för bilden
    p face_path = "uploaded_pictures/faces/#{params[:player_face][:filename]}"
    p club_path = "uploaded_pictures/clubs/#{params[:club][:filename]}"

    File.open(file_face_path, "wb") do |f|
        f.write(params[:player_face][:tempfile].read)
    end

    File.open(file_club_path, "wb") do |f|
        f.write(params[:club][:tempfile].read)
    end

    create_card(name, position, club_path, face_path, rating, stat1, stat2, stat3, session[:user_id])

    # puts image_path "uploaded_pictures/faces/neymar.png"
end

post('/buy') do
    add_to_inventory(card_data)
    # update ägaren av kortet, nya ägaren den som köpte
    redirect('/')
end

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