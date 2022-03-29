require_relative './app.rb'

#Anslutning till databas
def connect_to_db(path)
    db = SQLite3::Database.new(path)
    db.results_as_hash = true
    return db
end

#Registrering
def register_user(username, password, password_conf)
    db = connect_to_db('db/db.db')
    user = db.execute("SELECT * FROM users WHERE username = ?", username).first
    
    #Registeringskontroll, hantering av registrering
    if user == nil
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

#Logga in
def login_user(username, password)
    db = connect_to_db('db/db.db')
    user = db.execute("SELECT * FROM users WHERE username = ?", [username]).first
    # hashed_password = user["password"]

    if user == nil
        return slim(:"user/login", locals: { error: "Användaren finns inte!", sucess: "" })   
    elsif BCrypt::Password.new(user["password"]) == password
        session[:user_id] = user["id"]
        session[:username] = user["username"]
        puts "User id: #{session[:user_id]}"
        redirect('/webshop')
    else
        return slim(:"user/login", locals: { error: "Fel lösenord!", sucess: "" })
    end
end

#Funktion för att skapa kort
def create_card(name, position, club, face, rating, stat1, stat2, stat3, user_id)
    db = connect_to_db('db/db.db')
    db.execute("INSERT INTO cards (name, position, club, image, rating, user_id) VALUES (?,?,?,?,?,?)", [name, position, club, face, rating, user_id])
    db.execute("INSERT INTO stats (stat1, stat2, stat3) VALUES (?,?,?)", [stat1, stat2, stat3])
    File.open(file_face_path, "wb") do |f|
        f.write(params[:player_face][:tempfile].read)
    end
    File.open(file_club_path, "wb") do |f|
        f.write(params[:club][:tempfile].read)
    end
    redirect('/webshop')
end

#Funktion för att få användarens kort, inventory
# def get_user_cards()
#     db = connect_to_db('db/db.db')
#     user_cards = db.execute("SELECT * FROM cards where user_id = ?", session[:id])
#     user_cards_stats = db.execute("SELECT stat1, stat2, stat3 FROM stats where user_id = ?", session[:id])
#     return slim(:webshop, locals:{cards:user_cards, stats:user_cards_stats})
# end

#Funktion för att få ägaren av ett kort
def get_card_owner(id)
    db = connect_to_db("db/db.db")
    owner = db.execute("SELECT username FROM users WHERE id = ?", id)
    slim(:"webshop", locals:{owner:owner})
end

#Funktion för att få alla kort i databasen, webshop
def get_all_cards()
    if session["user_id"] != nil
        db = connect_to_db('db/db.db')
        cards = db.execute("SELECT * FROM cards")
        users = db.execute("SELECT * FROM users")
        # stats = db.execute("SELECT stat1, stat2, stat3 FROM stats")

        # stat_1_array = []
        # stat_2_array = []
        # stat_3_array = []

        # i = 0
        # while i < cards.length
        #     stat_1_array << stats[i]["stat1"]
        #     stat_2_array << stats[i]["stat2"]
        #     stat_3_array << stats[i]["stat3"]
        #     # stats:stats, stat1:stat_1_array, stat2:stat_2_array, stat3:stat_3_array
        #     i += 1
        # end
        return slim(:webshop, locals:{cards:cards, users:users})
    else
        redirect('/')
    end
end

#Funktion för att köpa kort
def buy_card(card_id)
    db = connect_to_db('db/db.db')
    db.execute("UPDATE cards SET user_id = ? WHERE id = ?", session[:user_id], card_id)
    redirect('/webshop')
end

#Funktion för att uppdatera kort
def update_card(card_id, name, rating, position)
    db = connect_to_db("db/db.db")
    db.execute("UPDATE cards SET name = ?, rating = ?, position = ? WHERE id = ?", name, rating, position, card_id)
    redirect('/webshop')
end

#Funktion för att ta bort kort
def delete_card(card_id)
    db = connect_to_db('db/db.db')
    db.execute("DELETE FROM cards where id = ?", card_id)
    redirect('/webshop')
    # location.reload()
end

# def temp()
#     db = connect_to_db('db/db.db')
#     # db.execute("SELECT * FROM cards where id = 1")
#     INSERT INTO cards (name, position, club, rating, face_image, user_id) VALUES ("Omar","Anfallare","Real Madrid",90,'\uploaded_pictures\ronaldo.png', 18)
# end

# puts temp()