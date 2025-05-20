# The main executable for AutoREST
require "thor"
require "sqlite3"

require_relative "autorest/version"
require_relative "autorest/quick_start"
require_relative "autorest/server"
require_relative "autorest/db/table"

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
        cli = AutoREST::QuickStart.new
        opts = cli.inquire
        db = SQLite3::Database.new('chinook.db')
        db_obj = AutoREST::DB.new(:sqlite, "chinook", db)
        puts db_obj.get_tables
        puts '-'*30
        p db_obj.get_columns("Albums")
    end
end