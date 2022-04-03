require_relative './app.rb'

#Anslutning till databas
def connect_to_db(path)
    db = SQLite3::Database.new(path)
    db.results_as_hash = true
    return db
end

#Registrering
def register_user(username, password, password_conf)
    db = connect_to_db("db/db.db")
    user = db.execute("SELECT * FROM users WHERE username = ?", username).first
    
    #Registeringskontroll, hantering av registrering
    if user == nil
        if password == password_conf
          hashed_password = BCrypt::Password.create(password)
          db.execute("INSERT INTO users (username, password) VALUES (?, ?)", [username, hashed_password])
          flash[:register_sucess] = "Du är registrerad, logga in för att se webbshoppen"
          redirect "/login"
        elsif user != nil && password != password_conf
            flash[:wrong_conf] = "Lösenorden matchar inte!"
            flash[:username_exist] = "Användarnamnet är upptaget!"
            redirect "/register"
        end
    else
        flash[:username_exist] = "Användarnamnet är upptaget!"
        redirect "/register"
    end
end

#Logga in
def login_user(username, password)
    db = connect_to_db('db/db.db')
    user = db.execute("SELECT * FROM users WHERE username = ?", [username]).first
    # hashed_password = user["password"]
    if user == nil
        flash[:no_such_user] = "Användaren finns inte!"
        redirect "/login"
    elsif BCrypt::Password.new(user["password"]) == password
        session[:user_id] = user["id"]
        session[:username] = user["username"]
        redirect "/webshop"
    else
        flash[:wrong_pass] = "Fel lösenord!"
        redirect "/login"
    end
end

#Funktion för att få användarens kort, inventory
# def inventory()
#     db = connect_to_db("db/db.db")
#     user_cards = db.execute("SELECT * FROM cards where user_id = ?", session[:user_id])
#     card_id = db.execute("SELECT id FROM cards where user_id = ?", session[:user_id])
#     user_cards_stats = db.execute("SELECT stat1, stat2 FROM card_stats_rel where card_id = ?", card_id)
#     return slim(:webshop, locals:{cards:user_cards, stats:user_cards_stats})
# end

#Funktion för att få ägaren av ett kort
def get_card_owner(id)
    db = connect_to_db("db/db.db")
    owner = db.execute("SELECT username FROM users WHERE id = ?", id)
    slim(:"webshop", locals:{owner:owner})
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
def create_card(name, position, club, face, rating, stat1, stat2, stat1_num, stat2_num, user_id)
    #ansluter till databasen
    db = connect_to_db("db/db.db")
    
    #creating card
    db.execute("INSERT INTO cards (name, position, club, image, rating, user_id) VALUES (?,?,?,?,?,?)", [name, position, club, face, rating, user_id])
    p created_card_id = db.execute("SELECT id from cards").last
    id = created_card_id["id"].to_i
    
    #insertion of stats
    db.execute("INSERT INTO card_stats_rel (card_id, stat_id, stat2_id) VALUES (?,?,?)", [id, stat1_num, stat2_num])
    p "spelarens stats har lagts till"
    
    #Skriver in filerna för ansikte och klubb i respektive path
    File.open(("public/" + club), "wb") do |f|
        f.write(params[:club][:tempfile].read)
    end
    File.open(("public/" + face), "wb") do |f|
        f.write(params[:player_face][:tempfile].read)
    end
    
    #Redirectar till webshop med det nya kortet
    flash[:sucess] = "Du har skapat ett nytt kort"
    redirect "/webshop"
end

#Funktion för att få alla kort i databasen, webshop
def get_all_cards()
    if session["user_id"] != nil

        db = connect_to_db("db/db.db") #Ansluter till databasen
        
        #Hämtar stats från och kort från databasen
        cards = db.execute("SELECT * FROM cards")
        p stats = db.execute("SELECT stat1_id, stat2_id FROM card_stats_rel")
        
        #Initerar variabler
        first_stats = []
        second_stats = []
        stats_1_names = []
        stats_2_names = []
        
        #While loop för att få ut stats
        i = 0
        while i <= (cards.length - 1)
            first_stats << stats[i]["stat1_id"]
            i += 1
        end
        
        #While loop för att få ut stats
        j = 0
        while j <= (cards.length - 1)
            second_stats << stats[j]["stat2_id"]
            j += 1
        end

        #While loop för att få ut stats namn
        first_stats.each do |stat|
            if stat == 1
                stats_1_names << "Snabbhet"
            elsif stat == 2
                stats_1_names << "Skott"
            elsif stat == 3
                stats_1_names << "Passningar"
            elsif stat == 4
                stats_1_names << "Styrka"
            elsif stat == 5
                stats_1_names << "Skicklighet"
            elsif stat == 6
                stats_1_names << "Dribbling"
            elsif stat == 7
                stats_1_names << "Uthållighet"
            end
        end

        #While loop för att få ut stats namn
        second_stats.each do |stat|
            if stat == 1
                stats_2_names << "Snabbhet"
            elsif stat == 2
                stats_2_names << "Skott"
            elsif stat == 3
                stats_2_names << "Passningar"
            elsif stat == 4
                stats_2_names << "Styrka"
            elsif stat == 5
                stats_2_names << "Skicklighet"
            elsif stat == 6
                stats_2_names << "Dribbling"
            elsif stat == 7
                stats_2_names << "Uthållighet"
            end
        end
        
        # p first_stats
        # p second_stats
        # p stats_1_names
        # p stats_2_names
        return slim(:webshop, locals:{cards:cards, stat1:stats_1_names, stat2:stats_2_names})

    else
        flash["error"] = "Du måste logga in för att se webshoppen"
        redirect "/"
    end
end

#Funktion för att köpa kort
def buy_card(card_id)
    db = connect_to_db('db/db.db')
    db.execute("UPDATE cards SET user_id = ? WHERE id = ?", session[:user_id], card_id)
    flash[:sucess] = "Du har köpt kortet"
    redirect "/webshop"
end

#Funktion för att uppdatera kort
def update_card(card_id, name, rating, position)
    db = connect_to_db("db/db.db")
    db.execute("UPDATE cards SET name = ?, rating = ?, position = ? WHERE id = ?", name, rating, position, card_id)
    flash[:sucess] = "Kortet har uppdaterats"
    redirect "/webshop"
end

def update_card_without_position(card_id, name, rating)
    db = connect_to_db("db/db.db")
    db.execute("UPDATE cards SET name = ?, rating = ? WHERE id = ?", name, rating, card_id)
    flash[:sucess] = "Kortet har uppdaterats"
    redirect "/webshop"
end

#Funktion för att ta bort kort
def delete_card(card_id)
    db = connect_to_db('db/db.db')
    db.execute("DELETE FROM cards where id = ?", card_id)
    flash[:sucess] = "Kortet har tagits bort"
    redirect "/webshop"
end

# def temp()
#     db = connect_to_db('db/db.db')
#     # db.execute("SELECT * FROM cards where id = 1")
#     INSERT INTO cards (name, position, club, rating, face_image, user_id) VALUES ("Omar","Anfallare","Real Madrid",90,'\uploaded_pictures\ronaldo.png', 18)
# end

# puts temp()

def omar()
    db = connect_to_db("db/db.db")
    cards = db.execute("SELECT * FROM cards")
    p info = db.execute("SELECT card_id, stat1_id, stat2_id FROM card_stats_rel")
    p stats = db.execute("SELECT stat1_id, stat2_id FROM card_stats_rel")
    
    first_stats = []
    # second_stats = []
    # stats_1_names = []
    # stats_2_names = []
    
    # p cards.length #2
    # p stats[0]["stat1_id"]
    # p stats[1]["stat1_id"]
    # p stats[2]["stat1_id"]

    i = 0
    while i <= (cards.length - 1)
        first_stats << stats[i]["stat1_id"]
        i += 1
    end

    # j = 0
    # while j < (cards.length - 1)
    #     second_stats << stats[j]["stat2_id"]
    #     j += 1
    # end

    p first_stats
    # p second_stats

    # first_stats.each do |stat|
    #     if stat == 1
    #         stats_1_names << "Snabbhet"
    #     elsif stat == 2
    #         stats_1_names << "Skott"
    #     elsif stat == 3
    #         stats_1_names << "Passningar"
    #     elsif stat == 4
    #         stats_1_names << "Styrka"
    #     elsif stat == 5
    #         stats_1_names << "Skicklighet"
    #     elsif stat == 6
    #         stats_1_names << "Dribbling"
    #     elsif stat == 7
    #         stats_1_names << "Uthållighet"
    #     end
    # end

    # second_stats.each do |stat|
    #     if stat == 1
    #         stats_2_names << "Snabbhet"
    #     elsif stat == 2
    #         stats_2_names << "Skott"
    #     elsif stat == 3
    #         stats_2_names << "Passningar"
    #     elsif stat == 4
    #         stats_2_names << "Styrka"
    #     elsif stat == 5
    #         stats_2_names << "Skicklighet"
    #     elsif stat == 6
    #         stats_2_names << "Dribbling"
    #     elsif stat == 7
    #         stats_2_names << "Uthållighet"
    #     end
    # end

    # p stats_1_names
    # p stats_2_names
end