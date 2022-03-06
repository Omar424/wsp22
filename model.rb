require_relative './app.rb'

def connect_to_db(path)
    db = SQLite3::Database.new(path)
    db.results_as_hash = true
    return db
end

def register_user(username, password, password_conf)
    db = connect_to_db('db/db.db')
    user_existance = db.execute("SELECT * FROM users WHERE username = ?", [username])
    
    #Registeringskontroll, hantering av registrering
    if user_existance.empty?
        if password == password_conf
          crypted_password = BCrypt::Password.create(password)
          db.execute("INSERT INTO users (username, password) VALUES (?, ?)", [username, crypted_password])
          return slim(:"user/login", locals: { error: "", sucess: "Logga in för att se webshoppen" })
        else
          return slim(:"user/register", locals: { error: "Passwords does not match" })
        end
    else
        return slim(:"user/register", locals: { error: "Username already exists" })
    end
end

def login_user(username, password)
    db = connect_to_db('db/db.db')
    user = db.execute("SELECT * FROM users WHERE username = ?", [username]).first
    p user
    user_password = user["password"]
    p user_password
    user_id = user["id"]
    p user_id

    if user.empty?
        return slim(:"user/login", locals: { error: "Användaren finns inte!", sucess: "" })   
    elsif BCrypt::Password.new(user_password) == password
        session[:user_id] = user["id"]
        puts "User id: #{session[:user_id]}"
        puts "User #{user}"
        redirect('/webshop')
    else
        return slim(:"user/login", locals: { error: "Fel lösenord!", sucess: "" })
    end

end

def add_to_inventory()
    #kod
    db = connect_to_db('db/db.db')
    db.execute("INSERT INTO ")
end

def create_card(name, position, club, rating, top_stat, image)
    db = connect_to_db('db/db.db')
    db.execute("INSERT INTO cards (name, position, club, rating, top_stat, image) VALUES (?,?,?,?,?,?)", [name, position, club, rating, top_stat, image])
end