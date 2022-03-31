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
        flash[:error] = "Användaren finns inte!"
        redirect "/login"
    elsif BCrypt::Password.new(user["password"]) == password
        session[:user_id] = user["id"]
        session[:username] = user["username"]
        puts "User id: #{session[:user_id]}"
        flash[:sucess]
        redirect "/webshop"
    else
        flash[:error] = "Fel lösenord!"
        redirect "/login"
    end
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
        stats = db.execute("SELECT card_id, stat_id FROM card_stats_rel")
        
        stat_dict = stats = {1 => "Snabbhet", 2 => "Skott", 3 => "Passningar", 4 => "Styrka", 5 => "Skicklighet", 6 => "Dribbling",7 => "Uthållighet"}
        
        
        # i = 0
        # while i < stat_dict.length
        #     if 
        # end
        
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

def convert_stats()
    db = connect_to_db("db/db.db")
    p stats = db.execute("SELECT card_id, stat_id FROM card_stats_rel").last
    puts "#{stats["stat_id"]} blev konverterad till"
    
    # stats.each do |stat|
    #     p stat = stat
    # end
    
    statname = ""
    
    if stats["stat_id"] == 1
        statname = "Snabbhet"
    elsif stats["stat_id"] == 2
        statname = "Skott"
    elsif stats["stat_id"] == 3
        statname = "Passningar"
    elsif stats["stat_id"] == 4
        statname = "Styrka"
    elsif stats["stat_id"] == 5
        statname = "Skicklighet"
    elsif stats["stat_id"] == 6
        statname = "Dribbling"
    elsif stats["stat_id"] == 7
        statname = "Uthållighet"
    end
    
    puts "#{statname}"
end

#Funktion för att skapa kort
def create_card(name, position, club, face, rating, stat1, stat2, stat3, user_id)
    #ansluter till databasen
    db = connect_to_db("db/db.db")

    #creating card
    db.execute("INSERT INTO cards (name, position, club, image, rating, user_id) VALUES (?,?,?,?,?,?)", [name, position, club, face, rating, user_id])
    p created_card_id = db.execute("SELECT id from cards").last
    id = created_card_id["id"].to_i
    
    #insertion of stats
    db.execute("INSERT INTO card_stats_rel (card_id, stat_id) VALUES (?,?)", [id, stat1])
    db.execute("INSERT INTO card_stats_rel (card_id, stat_id) VALUES (?,?)", [id, stat2])
    db.execute("INSERT INTO card_stats_rel (card_id, stat_id) VALUES (?,?)", [id, stat3])
    p "spelarens stats har lagts till"
    
    #Skriver in filerna för ansikte och klubb i respektive path
    File.open(("public/" + club), "wb") do |f|
        f.write(params[:club][:tempfile].read)
    end
    File.open(("public/" + face), "wb") do |f|
        f.write(params[:player_face][:tempfile].read)
    end
    redirect('/webshop')
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