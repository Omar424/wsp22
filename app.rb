require 'sinatra'
require 'slim'
require 'sqlite3'
require 'bcrypt'

get('/') do
    return slim(:index)
end

get('/register') do
    return slim(:register)
end

post('/register') do
    return slim(:index)
end