require 'sinatra'
require 'slim'
require 'sqlite3'
require 'bcrypt'

enable :sessions

def connect_to_db(path)
    db = SQLite3::Database.new(path)
    db.results_as_hash = true
    return db
end

get('/') do
    return slim(:index)
end

get('/register') do
    return slim(:register)
end

get('/login') do
    slim(:login)
end

get('/inventory') do

    if session["user_id"] != nil
        connect_to_db(path)
        inventory = db.execute("SELECT * FROM todos WHERE user_id = ?", [session["user_id"]])
        slim(:"inventory", locals: { inventory: inventory })
    else
        redirect("/")
    end

end

get('/webshop') do

    lines = File.readlines('cards_info.csv')

    double_array = lines.map do |element|
        element.split(",")
    end

    connect_to_db(path)
    card = db.execute("SELECT * FROM cards"])
    
    array_with_hashes = double_array.map do |element| {
        name:element[0],
        club:element[1],
        nation:element[2],
        picture:element[3],
        rating:element[4],
        position:element[5]
    }
    end

    # return slim(:webshop, locals:{card: card})
    return slim(:webshop, locals:{info:array_with_hashes})
end

post('/register') do
    username = params["username"]
    password = params["password"]
    password_confirmation = params["password_confirmation"]
    connect_to_db('db/db.db')
    check_user = db.execute("SELECT * FROM users WHERE username = ?", [username])
    
    #Registeringskontroll
    if check_user.empty?
        if password == password_confirmation
          hashed_password = BCrypt::Password.create(password)
          db.execute("INSERT INTO users (username, password) VALUES (?, ?)", [username, hashed_password])
          return slim(:login, locals: { error: "", sucess: "Logga in för att se dina todos" })
        else
          return slim(:register, locals: { error: "Passwords does not match" })
        end
    else
        return slim(:register, locals: { error: "Username already exists" })
    end
end

post('/login') do
    username = params["log_username"]
    password = params["log_password"]
    connect_to_db('path')
    user = db.execute("SELECT * FROM users WHERE username = ?", [username])

    #Användarhantering med inloggning
    if user.empty?
        # Fel hantering, visar att användaren inte finns!
        return slim(:login, locals: { error: "Användaren finns inte!", sucess: "" })   
    elsif BCrypt::Password.new(user[0]["password"]) == password
        session[:user_id] = user[0]["id"]
        puts "User id: #{session[:user_id]}"
        redirect('/teams')
    else
        # Fel hantering, visar att lösenordet inte matchar!
        return slim(:login, locals: { error: "Fel lössenord!", sucess: "" })
    end

end

post('/buy') do
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