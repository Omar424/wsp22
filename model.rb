require_relative './app.rb'

def connect_to_db(path)
    db = SQLite3::Database.new(path)
    db.results_as_hash = true
    return db
end

def register_user(username, password, password_conf)
    connect_to_db('db/db.db')
    check_user = db.execute("SELECT * FROM users WHERE username = ?", [username])
    
    #Registeringskontroll, hantering av registrering
    if check_user.empty?
        if password == password_conf
          crypted_password = BCrypt::Password.create(password)
          db.execute("INSERT INTO users (username, password) VALUES (?, ?)", [username, crypted_password])
          return slim(:"user/login", locals: { error: "", sucess: "Nice, du blev registrerad" })
        else
          return slim(:"user/register", locals: { error: "Passwords does not match" })
        end
    else
        return slim(:"user/register", locals: { error: "Username already exists" })
    end
end

def login_user(username, password)
    connect_to_db(path)
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

def create_player(name, position, club, key_stats, rating, image)
    connect_to_db('db/db.db')
    db.execute("INSERT INTO cards (name, position, club, rating, key_stats, image) VALUES (?,?,?,?,?,?)", [name, position, club, rating, key_stats, image])
    return slim(:"cards/new", locals: {create_done:"Spelare skapad, finns i webshop och din inventory"})
end