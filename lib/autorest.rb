# The main executable for AutoREST
require "thor"
require "tty-prompt"
require "rack"
require "rack/handler/puma"

require_relative "autorest/version"
require_relative "autorest/server"
require_relative "autorest/db/sqlite"

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
        opts = {db: {}, server: {}}
        puts "Welcome to AutoREST API Server Generator"
        opts[:db][:kind] = prompt.select("Select your database:",
                                {"SQLite" => :sqlite, "MySQL" => :mysql}, 
                                default: "SQLite")

        if opts[:db][:kind] == :sqlite
            opts[:db][:name] = prompt.ask("Enter your database name:")
            db = AutoREST::SQLiteDB.new(opts[:db][:name])
        else
            # TODO: Add MySQL support
        end

        opts[:db][:tables] = prompt.multi_select("Select tables from database:", db.tables)
        db.set_access_tables(opts[:db][:tables])
        puts "Creating configuration file..."
        puts "Successfully completed!"
        puts "-" * 30
        puts "Starting server..."
        server = AutoREST::Server.new(db)
        Rack::Handler::Puma.run(server, Port: 7914)
    end
end