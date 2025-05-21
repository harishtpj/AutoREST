# The main executable for AutoREST
require "thor"
require "sqlite3"
require "tty-prompt"
require "rack"
require "rack/handler/puma"

require_relative "autorest/version"
require_relative "autorest/server"
require_relative "autorest/db/adapter"

class AutoREST::CLI < Thor
    def self.exit_on_failure?
        true
    end

    map "-v" => "version"
    desc "version", "Prints the version of AutoREST"
    def version
        puts "AutoREST v#{AutoREST::VERSION}"
    end

    map "-n" => "new"
    desc "new", "Creates a new AutoREST API server"
    def new
        prompt = TTY::Prompt.new
        puts "Welcome to AutoREST API Server Generator"

        dbkind = prompt.select("Select your database:", 
                                {"SQLite" => :sqlite, "MySQL" => :mysql}, 
                                default: "SQLite")

        dbname = prompt.ask("Enter your database name:")
        db = SQLite3::Database.new(dbname)
        db.results_as_hash = true
        db_obj = AutoREST::DBAdapter.new(dbkind, dbname, db)

        dbtable = prompt.select("Select table from database:", db_obj.tables)
        puts "Creating configuration file..."
        puts "Successfully completed!"
        puts "-" * 30
        puts "Starting server..."
        server = AutoREST::Server.new(db_obj, dbtable)
        Rack::Handler::Puma.run(server, Port: 7914)
    end
end