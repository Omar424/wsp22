require 'sinatra'
require 'slim'
require 'sqlite3'
require 'bcrypt'

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

post('/register') do
    return slim(:index)
end

get('/teams') do
    return slim(:teams)
end

# before do
#     p "Before KÖRS, session_user_id är #{session[:user_id]}."

#     if (session[:user_id] ==  nil) && (request.path_info != '/')
#         session[:error] = "You need to log in to see this"
#         redirect('/error')
#     end
# end