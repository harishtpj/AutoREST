# The CLI interface to AutoREST Server Generator
require "tty-prompt"

class AutoREST::QuickStart
    def initialize
        @prompt = TTY::Prompt.new
        @opts = {}
    end

    def db_choices
        {
            "SQLite" => :sqlite,
            "MySQL" => :mysql
        }
    end

    def inquire
        puts "Welcome to AutoREST API Server Generator"
        @opts[:db] = @prompt.select("Select your database:", db_choices, default: "SQLite")
        puts "Creating configuration file..."
        puts "Successfully completed!"
    end
end