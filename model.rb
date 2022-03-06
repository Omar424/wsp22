require_relative './app.rb'

def connect_to_db(path)
    db = SQLite3::Database.new(path)
    db.results_as_hash = true
    return db
end

def register_user(username, password, password_conf)
    db = connect_to_db('db/db.db')
    user = db.execute("SELECT * FROM users WHERE username = ?", [username]).first
    
    #Registeringskontroll, hantering av registrering
    if user.empty?
        if password == password_conf
          hashed_password = BCrypt::Password.create(password)
          db.execute("INSERT INTO users (username, password) VALUES (?, ?)", [username, hashed_password])
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
    hashed_password = user["password"]

    if user.empty?
        return slim(:"user/login", locals: { error: "Användaren finns inte!", sucess: "" })   
    elsif BCrypt::Password.new(hashed_password) == password
        session[:user_id] = user["id"]
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

def create_card(name, position, club, rating, top_stat1, top_stat2, top_stat3, image)
    db = connect_to_db('db/db.db')
    db.execute("INSERT INTO cards (name, position, club, rating, image) VALUES (?,?,?,?,?)", [name, position, club, rating, image])
    db.execute("INSERT INTO top_stats (top_stat1, top_stat2, topstat3) VALUES (?,?,?)", [top_stat1, top_stat2, top_stat3])
end