# The main server instance for AutoREST
require "sinatra"

class AutoREST::Server < Sinatra::Base
    def initialize
        super
    end

    get '/' do
        "Welcome to AutoREST API Server Generator"
    end
end