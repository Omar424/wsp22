module Model

    # Attempts to connect to database and return connection
    def connect_to_db(path)
        db = SQLite3::Database.new(path)
        db.results_as_hash = true
        return db
    end

    # Attempts to create a new user
    #
    # @params [String] username The username
    # @params [String] password The password
    # @params [String] password_conf The password confirmation
    #
    def register_user(username, password, password_conf)
        #Ansluter till databasen och hämtar användar-data
        db = connect_to_db("db/db.db")
        user = db.execute("SELECT * FROM users WHERE username = ?", username).first
        
        #Kollar om användarnamnet redan finns
        if user == nil
            if password == password_conf
                hashed_password = BCrypt::Password.create(password)
                db.execute("INSERT INTO users (username, password, role, coins) VALUES (?, ?, ?,?)", [username, hashed_password, "user", 0])
                flash[:register_sucess] = "Du är registrerad, logga in för att köpa kort och skapa egna kort"
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

    # Attempts to login a user
    #
    # @params [String] username The username
    # @params [String] password The password
    #
    def login_user(username, password)
        #Ansluter till databasen och hämtar användar-data
        db = connect_to_db("db/db.db")
        user = db.execute("SELECT * FROM users WHERE username = ?", [username]).first

        #Kollar om användaren finns
        if user == nil
            flash[:no_such_user] = "Användaren finns inte!"
            redirect "/login"
        elsif BCrypt::Password.new(user["password"]) == password
            session[:logged_in] = true
            session[:username] = user["username"]
            session[:role] = user["role"]
            session[:coins] = user["coins"]
            redirect "/webshop"
        else
            flash[:wrong_pass] = "Fel lösenord!"
            redirect "/login"
        end
    end

    # Converts an integer to a stat string
    #
    # @params [Integer] stat The stat to convert
    #
    def convert_to_statname(array)
        length = array.length
        array.each do |stat|
            if stat == 1
                array << "Snabb"
            elsif stat == 2
                array << "Bra skott"
            elsif stat == 3
                array << "Bra passningar"
            elsif stat == 4
                array << "Stark"
            elsif stat == 5
                array << "Skicklig"
            elsif stat == 6
                array << "Bra dribbling"
            elsif stat == 7
                array << "Bra uthållighet"
            end
        end
        array.shift(length)
    end

    # Attempts to show one card
    #
    # @params [String] id The id of the card
    #
    def show_one_card(card_id)
        db = connect_to_db("db/db.db")
        card = db.execute("SELECT * FROM cards WHERE id = ?", card_id).first
        card_stats = db.execute("SELECT stat1_id, stat2_id FROM card_stats_rel WHERE card_id = ?", card_id).first
        
        if card == nil
            flash[:error] = "Kortet med id #{card_id} finns inte"
            redirect "/webshop"
        else
            first_stats = []
            second_stats = []
            first_stats << card_stats["stat1_id"]
            second_stats << card_stats["stat2_id"]
            convert_to_statname(first_stats)
            convert_to_statname(second_stats)
            slim(:"/cards/show", locals:{card:card, stat1:first_stats, stat2:second_stats})
        end
    end

    # Attempts to show the inventory of a user
    #
    # @params [String] username The username of the user
    #
    def get_inventory(user)
        if session["logged_in"] == true
            
            #Ansluter till databasen
            db = connect_to_db("db/db.db")
            
            #Deklarerar variabler
            card_ids = []
            stats = []
            first_stats = []
            second_stats = []
            
            #Hämtar data om användarens
            user_data = db.execute("SELECT * FROM users WHERE username = ?", user).first
            #Hämtar data om korten
            user_cards = db.execute("SELECT * FROM cards where owner = ?", user)
            #Hämtar id'n för korten
            card_ids = db.execute("SELECT id FROM cards where owner = ?", user)
            
            #Hämtar stats för korten
            card_ids.each do |id|
                stat = db.execute("SELECT stat1_id, stat2_id FROM card_stats_rel WHERE card_id = ?", id["id"])
                stats << stat
            end
            
            stats.each_with_index do |stat|
                first_stats << stat[0]["stat1_id"]
                second_stats << stat[0]["stat2_id"]
            end
            
            convert_to_statname(first_stats)
            convert_to_statname(second_stats)

            #Om användaren inte finns
            if user_data == nil
                flash[:error] = "Användaren #{user} finns inte"
                redirect "/webshop"
            else
                slim(:"inventory", locals:{user:user_data, cards:user_cards, stat1:first_stats, stat2:second_stats})
            end
        else
            flash[:error] = "Du måste vara inloggad för att se en inventory"
            redirect "/"
        end
    end

    # Attempts to create a card
    #
    # @param [String] owner, owner of the card
    # @param [String] name, name of the card
    # @param [String] position, position of the card
    # @param [Integer] rating, rating of the card
    # @param [Integer] price, price of the card
    # @param [String] club, club of the card
    # @param [String] image, image of the card
    # @param [String] stat1, first stat of the card
    # @param [String] stat2, second stat of the card
    #
    def create_card(name, position, club, face, rating, stat1, stat2, stat1_num, stat2_num, owner, price)
        #ansluter till databasen
        db = connect_to_db("db/db.db")
        
        #creating card
        db.execute("INSERT INTO cards (owner, name, position, club, image, rating, price) VALUES (?,?,?,?,?,?,?)", [owner, name, position, club, face, rating, price])
        p latest_card_id = db.execute("SELECT id from cards").last
        id = latest_card_id["id"].to_i
        
        #insertion of stats
        db.execute("INSERT INTO card_stats_rel (card_id, stat1_id, stat2_id) VALUES (?,?,?)", [id, stat1_num, stat2_num])

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

    # Attempts to display form to make a new card
    def new_card()
        if session["logged_in"] == true
            db = connect_to_db("db/db.db")
            stats = db.execute("SELECT stats FROM stat")
            slim(:"cards/new", :locals => {stats: stats})
        else
            flash[:error] = "Logga in för att skapa ett kort"
            redirect "/"
        end
    end

    # Attempts to display all cards in the database
    def get_all_cards()
        #Ansluter till databasen och hämtar alla kort
        db = connect_to_db("db/db.db")
        
        #Hämtar stats och kort från databasen
        coins = db.execute("SELECT coins FROM users WHERE username = ?", session[:username]).first
        cards = db.execute("SELECT * FROM cards")
        stats = db.execute("SELECT stat1_id, stat2_id FROM card_stats_rel")

        #Initerar variabler
        first_stats = []
        second_stats = []

        stats.each_with_index do |stat|
            first_stats << stat["stat1_id"]
        end

        stats.each_with_index do |stat|
            second_stats << stat["stat2_id"]
        end

        #While loop för att få ut stats namn
        convert_to_statname(first_stats)
        convert_to_statname(second_stats)

        slim(:webshop, locals:{cards:cards, stat1:first_stats, stat2:second_stats, coins:coins})
    end

    # Attempts to display form to add coins to a user
    def make_coins()
        if session[:logged_in] == true
            slim(:coins)
        else
            flash[:error] = "Du måste logga in för att komma åt sidan"
            redirect "/"
        end
    end

    # Attempts to add coins to a user
    # @param [String] username, username of the user
    # @param [Integer] coins, amount of coins to add
    #
    def earn_coins(coins)
        db = connect_to_db("db/db.db")
        user = db.execute("SELECT * FROM users WHERE username = ?", session[:username]).first
        db.execute("UPDATE users SET coins = ? WHERE username = ?", [user["coins"] + coins, session[:username]])
        flash[:sucess] = "Det har nu lagts till #{coins} mynt till ditt konto"
        redirect "/webshop"
    end

    # Attempts to buy a specific card
    # @param [String] card_id, id of the card to buy
    #
    def buy_card(card_id)
        db = connect_to_db('db/db.db')
        
        card = db.execute("SELECT * FROM cards WHERE id = ?", card_id).first
        card_price = card["price"].to_i
        seller = card["owner"]
        
        client_info = db.execute("SELECT * FROM users WHERE username = ?", session["username"]).first
        client_name = client_info["username"]
        client_coins = client_info["coins"].to_i    

        seller_info = db.execute("SELECT * FROM users WHERE username = ?", seller).first
        seller_coins = seller_info["coins"]

        if client_name == seller
            flash[:error] = "Du kan inte köpa ett kort som du säljer"
            redirect "/webshop"
        end

        if client_coins < card_price
            flash[:error] = "Du har inte råd med kortet"
            redirect "/webshop"
        else
            db.execute("UPDATE users SET coins = ? WHERE username = ?", [(client_coins - card_price), client_name])
            db.execute("UPDATE users SET coins = ? WHERE username = ?", [(seller_coins + card_price), seller])
            db.execute("UPDATE cards SET owner = ? WHERE id = ?", [client_name, card_id])
            flash[:sucess] = "Du har köpt kortet"
            redirect "/webshop"
        end
    end

    # Attempts to display form to edit a card
    def edit_card(card_id)
        if session["logged_in"] == true
            db = connect_to_db('db/db.db')
            user = db.execute("SELECT * FROM users WHERE username = ?", session["username"]).first
            card = db.execute("SELECT * FROM cards WHERE id = ?", card_id).first
            card_stats = db.execute("SELECT stat1_id, stat2_id FROM card_stats_rel WHERE card_id = ?", card_id).first

            if card["owner"] == session["username"] || user["role"] == "admin"
                first_stats = []
                second_stats = []
                first_stats << card_stats["stat1_id"]
                second_stats << card_stats["stat2_id"]
                convert_to_statname(first_stats)
                convert_to_statname(second_stats)
                slim(:"/cards/edit", locals:{card:card, stat1:first_stats, stat2:second_stats})
            elsif card == nil
                flash[:error] = "Kortet med id #{card_id} finns inte"
                redirect "/webshop"
            elsif session["username"] != card["owner"]
                flash[:error] = "Du kan inte redigera ett kort du inte äger"
                redirect "/webshop"
            end
        else
            flash[:error] = "Logga in för att redigera ett kort"
            redirect "/"
        end
    end

    # Attempts to update a card
    # @param [String] card_id, id of the card to update
    # @param [String] name, name of the card to update
    # @param [Integer] rating, rating of the card to update
    # @param [String] position, position of the card to update
    #
    def update_card(card_id, name, rating, position)
        if session[:logged_in] == true
            db = connect_to_db("db/db.db")
            if position == nil
                db.execute("UPDATE cards SET name = ?, rating = ? WHERE id = ?", name, rating, card_id)
                flash[:sucess] = "Kortet har uppdaterats"
                redirect "/webshop"
            else
                db.execute("UPDATE cards SET name = ?, rating = ?, position = ? WHERE id = ?", name, rating, position, card_id)
                flash[:sucess] = "Kortet har uppdaterats"
                redirect "/webshop"
            end
        else
            flash[:error] = "Logga in för att komma åt sidan"
            redirect "/"
        end
    end

    # Attempts to delete a card
    # @param [String] card_id, id of the card to delete
    #
    def delete_card(card_id)
        if session["logged_in"] == true
            db = connect_to_db("db/db.db")
            user_info = db.execute("SELECT role, username FROM users WHERE username = ?", session[:username]).first
            owner = db.execute("SELECT owner FROM cards WHERE id = ?", card_id).first
            if user_info["role"] == "admin" || user_info["username"] == owner["owner"]
                db.execute("DELETE FROM cards where id = ?", card_id)
                db.execute("DELETE FROM card_stats_rel where card_id = ?", card_id)
                flash[:sucess] = "Kortet har tagits bort"
                redirect "/webshop"
            else
                flash[:error] = "Du har inte tillräckligt med rättigheter för att göra detta"
                redirect "/"
            end
        else
            flash[:error] = "Du måste logga in för att komma åt sidan"
            redirect "/"
        end
    end

end