require 'sinatra'
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

get('/error') do
    slim(:error)
end

# get('/cards') do
#     ska visa användarens alla skapta bilder med hjälp av SQL query
#     slim(:"cards/index")
# end

get('/inventory') do
    if session["user_id"] != nil
        connect_to_db(path)
        inventory = db.execute("SELECT * FROM cards WHERE user_id = ?", [session["user_id"]])
        slim(:"inventory", locals: { inventory: inventory })
    else
        redirect('/')
    end
end

get('/webshop') do
    get_all_cards()
end

get('/card/:id') do
    db = db_connection(path)
    card_id = params[:id]

    card_data = db.execute("SELECT * FROM cards WHERE id=(?)", card_id).first

    if card_data.nil?
        session[:message] = "card does not exist"
        redirect('/error')
    end

    slim(:"cards/index", locals:{card_info:card_data})
end

#Man ska inte komma till denna routen utan att vara inloggad, session_id ska vara tillgängligt
get('/cards/new') do
    slim(:"cards/new")
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
    club = params[:club]
    rating = params[:rating]
    stat1 = params[:stat1]
    stat2 = params[:stat2]
    stat3 = params[:stat3]
    user_id = 100
    image_path = File.join("/uploaded_pictures/", params[:image][:filename])
    puts image_path #/uploaded_pictures/tree.jpg
    
    # File.write(path, File.read(params[:image][:tempfile]))
    create_card(name, position, club, stat1, stat2, stat3, rating, image_path, user_id)
    # insert_stats(top_stat1, top_stat2, top_stat3)

    redirect('/cards/new', locals:{klart: "kort skapat, den finns nu i webbshoppen"})
end

post('/buy') do
    # add_to_inventory(card_data)
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