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
    # hashed_password = user["password"]

    if user == nil
        return slim(:"user/login", locals: { error: "Användaren finns inte!", sucess: "" })   
    elsif BCrypt::Password.new(user["password"]) == password
        session[:user_id] = user["id"]
        redirect('/webshop')
    else
        return slim(:"user/login", locals: { error: "Fel lösenord!", sucess: "" })
    end
end

def get_cards()
    db = connect_to_db('db/db.db')
    user_cards = db.execute("SELECT * FROM cards where user_id = ?", user_id)
    return slim(:webshop, locals:{cards:user_cards, stats:all_stats})
end

def get_all_cards()
    db = connect_to_db('db/db.db')
    cards = db.execute("SELECT * FROM cards")
    stats = db.execute("SELECT * FROM stats")
    p cards
    p stats
    puts stats[0]
    
    return slim(:webshop, locals:{cards:cards, stats:stats})
end

def add_to_inventory()
    #kod
    db = connect_to_db('db/db.db')
    db.execute("UPDATE VALUES user_id to user_id")
end

def create_card(name, position, club, face, rating, stat1, stat2, stat3, user_id)
    db = connect_to_db('db/db.db')
    db.execute("INSERT INTO cards (name, position, club, image, rating, user_id) VALUES (?,?,?,?,?,?)", [name, position, club, face, rating, user_id])
    db.execute("INSERT INTO stats (stat1, stat2, stat3) VALUES (?,?,?)", [stat1, stat2, stat3])
    redirect('/cards/new', locals:{klart: "kort skapat, den finns nu i webbshoppen"})
end

# def temp()
#     db = connect_to_db('db/db.db')
#     # db.execute("SELECT * FROM cards where id = 1")
#     INSERT INTO cards (name, position, club, rating, face_image, user_id) VALUES ("Omar","Anfallare","Real Madrid",90,'\uploaded_pictures\ronaldo.png', 18)
# end

# puts temp()