require_relative './app.rb'

#Anslutning till databas
def connect_to_db(path)
    db = SQLite3::Database.new(path)
    db.results_as_hash = true
    return db
end

#Registrering
def register_user(username, password, password_conf)
    #Ansluter till databasen och hämtar användar-data
    db = connect_to_db("db/db.db")
    user = db.execute("SELECT * FROM users WHERE username = ?", username).first
    
    #Kollar om användarnamnet redan finns
    if user == nil
        if password == password_conf
          hashed_password = BCrypt::Password.create(password)
          db.execute("INSERT INTO users (username, password) VALUES (?, ?)", [username, hashed_password])
          flash[:register_sucess] = "Du är registrerad, logga in för att se webbshoppen"
          redirect "/login"
        elsif password != password_conf
            flash[:wrong_conf] = "Lösenorden matchar inte!"
            redirect "/"
        end
    else
        flash[:username_exist] = "Användarnamnet är upptaget!"
        redirect "/register"
    end
end

#Logga in
def login_user(username, password)
    #Ansluter till databasen och hämtar användar-data
    db = connect_to_db("db/db.db")
    user = db.execute("SELECT * FROM users WHERE username = ?", [username]).first

    #Kollar om användaren finns
    if user == nil
        flash[:no_such_user] = "Användaren finns inte!"
        redirect "/login"
    elsif BCrypt::Password.new(user["password"]) == password
        session[:username] = user["username"]
        session[:logged_in] = true
        redirect "/webshop"
    else
        flash[:wrong_pass] = "Fel lösenord!"
        redirect "/login"
    end
end

#Funktion för att visa ett specifikt kort
def show_one_card(card_id)
    if session["logged_in"] == true
        db = connect_to_db("db/db.db")
        card = db.execute("SELECT * FROM cards WHERE id = ?", card_id).first
        card_stats = db.execute("SELECT stat1_id, stat2_id FROM card_stats_rel WHERE card_id = ?", card_id).first

        if card == nil
            flash[:error] = "Kortet med id #{card_id} finns inte"
            redirect "/webshop"
        else
            slim(:"/cards/show", locals:{card:card, stats:card_stats})
        end

    else
        flash[:error] = "Logga in för att visa ett kort"
        redirect "/"
    end
end

#Funktion för att få användarens kort, inventory
def get_user_inventory(user_id)
    if session["logged_in"] == true
        db = connect_to_db("db/db.db")

        active_user_data = db.execute("SELECT * FROM users where id = ?", session["user_id"]).first
        user_data = db.execute("SELECT username FROM users where id = ?", user_id).first
        user_cards = db.execute("SELECT * FROM cards where user_id = ?", user_id)

        stats = db.execute("SELECT stat1_id, stat2_id FROM card_stats_rel")
        # p stats
    
        #Om användaren finns inte
        if user_data == nil
            flash[:error] = "Användare med id #{user_id} finns inte"
            redirect "/webshop"
        #Om användaren inte skapat några kort och det inte är den aktiva användaren
        elsif user_cards == nil && user_data["id"] != session["user_id"]
            flash[:error] = "Användaren #{session[:username]} har inte skapat några kort"
            redirect "/user/#{user_id}/inventory"
        #Om användaren inte skapat några kort och det är den aktiva användaren
        elsif user_cards == nil && user_data["id"] == session["user_id"]
            flash[:error] = "Du har inte skapat några kort"
            redirect "/user/#{user_id}/inventory"
        else
            slim(:"inventory", locals:{user:user_data, cards:user_cards, stats:stats})
        end
    else
        flash[:error] = "Du måste vara inloggad för att se en profil"
        redirect "/"
    end
end

def get_user_inventory(owner)
    if session["logged_in"] == true
        db = connect_to_db("db/db.db")

        user_data = db.execute("SELECT * FROM users where username = ?", owner).first
        p user_cards = db.execute("SELECT * FROM cards where owner = ?", owner)

        card_ids = []
        user_cards.each do |card|
            card_ids << card["id"]
        end
        p card_ids

        card_stats = []
        i = 0
        while i < card_ids.length
            stats = db.execute("SELECT stat1_id, stat2_id FROM card_stats_rel WHERE card_id = ?", card_ids[i])
            card_stats << stats
            i += 1
        end
        p card_stats

        #Om användaren finns inte
        if user_data == nil
            flash[:error] = "Användare med namn #{owner} finns inte"
            redirect "/webshop"
        #Om användaren inte skapat några kort och det inte är den aktiva användaren
        elsif user_cards == nil && owner != session["username"]
            flash[:error] = "#{owner} har inte skapat några kort"
            redirect "/webshop"
        #Om den aktiva användaren inte skapat några kort
        elsif owner == session["username"] && user_cards == nil
            flash[:error] = "Du har inte skapat några kort"
            redirect "/user/#{user_id}/inventory"
        else
            slim(:"inventory", locals:{owner:owner, cards:user_cards, stats:card_stats})
        end
    else
        flash[:error] = "Du måste vara inloggad för att se en profil"
        redirect "/"
    end
end

#Funktion för att skapa kort
def create_card(name, position, club, face, rating, stat1, stat2, stat1_num, stat2_num, owner)
    #ansluter till databasen
    db = connect_to_db("db/db.db")
    
    #creating card
    db.execute("INSERT INTO cards (owner, name, position, club, image, rating) VALUES (?,?,?,?,?,?)", [owner, name, position, club, face, rating])
    p latest_card_id = db.execute("SELECT id from cards").last
    id = latest_card_id["id"].to_i
    
    #insertion of stats
    db.execute("INSERT INTO card_stats_rel (card_id, stat1_id, stat2_id) VALUES (?,?,?)", [id, stat1_num, stat2_num])
    p "spelarens stats har lagts till"
    
    #Skriver in filerna för ansikte och klubb i respektive path
    File.open(("public/" + club), "wb") do |f|
        f.write(params[:club][:tempfile].read)
    end
    File.open(("public/" + face), "wb") do |f|
        f.write(params[:player_face][:tempfile].read)
    end
    
    #Redirectar till webshop med det nya kortet
    flash[:sucess] = "Ditt kort har skapats"
    redirect "/webshop"
end

#Funktion för att få alla kort i databasen, webshop
def get_all_cards()
    if session["logged_in"] == true
        #Ansluter till databasen och hämtar alla kort
        db = connect_to_db("db/db.db")
        
        #Hämtar stats och kort från databasen
        cards = db.execute("SELECT * FROM cards")
        stats = db.execute("SELECT stat1_id, stat2_id FROM card_stats_rel")
        
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

        return slim(:webshop, locals:{cards:cards, stat1:stats_1_names, stat2:stats_2_names})

    else
        flash["error"] = "Logga in för att se webshoppen"
        redirect "/"
    end
end

#Funktion för att köpa kort
def buy_card(card_id)
    db = connect_to_db('db/db.db')
    db.execute("UPDATE cards SET owner = ? WHERE id = ?", session[:username], card_id)
    flash[:sucess] = "Du har köpt kortet"
    redirect "/webshop"
end

def edit_card(card_id)
    if session["logged_in"] == true
        db = connect_to_db('db/db.db')
        card = db.execute("SELECT * FROM cards WHERE id = ?", card_id).first
        card_stats = db.execute("SELECT stat1_id, stat2_id FROM card_stats_rel WHERE card_id = ?", card_id).first
        
        if card == nil
            flash[:error] = "Kortet med id #{card_id} finns inte"
            redirect "/webshop"
        elsif card["owner"] != session["username"]
            flash[:error] = "Du kan inte redigera ett kort du inte äger"
            redirect "/webshop"
        else
            slim(:"/cards/edit", locals:{card:card, stats:card_stats})
        end
    else
        flash[:error] = "Logga in för att redigera ett kort"
        redirect "/"
    end
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

# def convert(statname)
#     if statname == "Snabbhet"
#         stat = 1
#     elsif statname == "Skott"
#         stat = 2
#     elsif statname == "Passningar"
#         stat = 3
#     elsif statname == "Styrka"
#         stat = 4
#     elsif statname == "Skicklighet"
#         stat = 5
#     elsif statname == "Dribbling"
#         stat = 6
#     elsif statname == "Uthållighet"
#         stat = 7
#     end
#     p stat
# end

# def omar()
#     db = connect_to_db("db/db.db")
#     cards = db.execute("SELECT * FROM cards")
#     p info = db.execute("SELECT card_id, stat1_id, stat2_id FROM card_stats_rel")
#     p stats = db.execute("SELECT stat1_id, stat2_id FROM card_stats_rel")
    
#     first_stats = []
#     second_stats = []
#     stats_1_names = []
#     stats_2_names = []

#     i = 0
#     while i <= (cards.length - 1)
#         first_stats << stats[i]["stat1_id"]
#         i += 1
#     end

#     j = 0
#     while j <= (cards.length - 1)
#         second_stats << stats[j]["stat2_id"]
#         j += 1
#     end

#     first_stats.each do |stat|
#         if stat == 1
#             stats_1_names << "Snabbhet"
#         elsif stat == 2
#             stats_1_names << "Skott"
#         elsif stat == 3
#             stats_1_names << "Passningar"
#         elsif stat == 4
#             stats_1_names << "Styrka"
#         elsif stat == 5
#             stats_1_names << "Skicklighet"
#         elsif stat == 6
#             stats_1_names << "Dribbling"
#         elsif stat == 7
#             stats_1_names << "Uthållighet"
#         end
#     end

#     second_stats.each do |stat|
#         if stat == 1
#             stats_2_names << "Snabbhet"
#         elsif stat == 2
#             stats_2_names << "Skott"
#         elsif stat == 3
#             stats_2_names << "Passningar"
#         elsif stat == 4
#             stats_2_names << "Styrka"
#         elsif stat == 5
#             stats_2_names << "Skicklighet"
#         elsif stat == 6
#             stats_2_names << "Dribbling"
#         elsif stat == 7
#             stats_2_names << "Uthållighet"
#         end
#     end
# end

#Funktion som konverterar stats från nummer till namn
# def convert_stats()
#     db = connect_to_db("db/db.db")
#     p stats = db.execute("SELECT card_id, stat_id FROM card_stats_rel").last
#     puts "#{stats["stat_id"]} blev konverterad till"
    
#     # stats.each do |stat|
#     #     p stat = stat
#     # end
    
#     statname = ""
    
#     if stats["stat_id"] == 1
#         statname = "Snabbhet"
#     elsif stats["stat_id"] == 2
#         statname = "Skott"
#     elsif stats["stat_id"] == 3
#         statname = "Passningar"
#     elsif stats["stat_id"] == 4
#         statname = "Styrka"
#     elsif stats["stat_id"] == 5
#         statname = "Skicklighet"
#     elsif stats["stat_id"] == 6
#         statname = "Dribbling"
#     elsif stats["stat_id"] == 7
#         statname = "Uthållighet"
#     end
    
#     puts "#{statname}"
# end