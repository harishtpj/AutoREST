# The main executable for AutoREST
#
# This file defines the command-line interface (CLI) for the AutoREST gem using Thor.
# The CLI allows users to generate a new AutoREST API server, start the server using 
# a configuration file or DSN, and view the current version of the API.
#
# Commands:
# - `version`: Prints the version of AutoREST.
# - `new`: Creates a new AutoREST API server project.
# - `server FILE`: Starts the AutoREST API server using a configuration file.
# - `boot DSN`: Starts the AutoREST API server using a DSN.
#
# The commands involve setting up a database connection and starting a server with 
# specified parameters such as the host, port, and database tables.

require "thor"
require "tty-prompt"
require "rack"
require "rack/handler/puma"
require "yaml"
require "uri"

require_relative "autorest/version"
require_relative "autorest/server"

class AutoREST::CLI < Thor

    # Determines if the program should exit on failure
    def self.exit_on_failure?
        true
    end

    map "-v" => "version"
    desc "version", "Prints the version of AutoREST"
    # Prints the version of AutoREST
    def version
        puts "AutoREST v#{AutoREST::VERSION}"
    end

    map "-n" => "new"
    desc "new", "Creates a new AutoREST API server"
    # Creates a new AutoREST API server project
    # Prompts the user for database details and creates a configuration file.
    def new
        prompt = TTY::Prompt.new
        opts = {db: {}, server: { host: "localhost", port: 7914 } }
        puts "Welcome to AutoREST API Server Generator"
        project_name = prompt.ask("Enter the project's name:")
        opts[:db][:kind] = prompt.select("Select your database:",
                                {"SQLite" => :sqlite, "MySQL" => :mysql, "PostgreSQL" => :pg, "Oracle" => :orcl}, 
                                default: "SQLite")

        if opts[:db][:kind] == :sqlite
            require_relative "autorest/db/sqlite"
            opts[:db][:name] = prompt.ask("Enter location of DB file:")
            db = AutoREST::SQLiteDB.new(opts[:db][:name])
        else
            def_port = {mysql: 3306, pg: 5432, orcl: 1521}
            def_usr = {mysql: "root", pg: "postgres", orcl: "SYS"}
            opts[:db][:host] = prompt.ask("Enter hostname of DB:", default: "localhost")
            opts[:db][:port] = prompt.ask("Enter port of DB:", default: def_port[opts[:db][:kind]])
            opts[:db][:user] = prompt.ask("Enter username:", default: def_usr[opts[:db][:kind]])
            opts[:db][:passwd] = prompt.ask("Enter password:", echo: false)
            opts[:db][:name] = prompt.ask("Enter database #{opts[:db][:kind] == :orcl ? "SID" : "name"}:")
            case opts[:db][:kind]
            when :mysql
                require_relative "autorest/db/mysql"
                db = AutoREST::MySQLDB.new(opts[:db][:host], opts[:db][:port], opts[:db][:user], opts[:db][:passwd], opts[:db][:name])
            when :pg
                require_relative "autorest/db/postgres"
                db = AutoREST::PostgresDB.new(opts[:db][:host], opts[:db][:port], opts[:db][:user], opts[:db][:passwd], opts[:db][:name])
            when :orcl
                require_relative "autorest/db/oracle"
                db = AutoREST::OracleDB.new(opts[:db][:host], opts[:db][:port], opts[:db][:user], opts[:db][:passwd], opts[:db][:name])
            end
        end

        opts[:db][:tables] = prompt.multi_select("Select tables from database:", db.tables)
        db.set_access_tables(opts[:db][:tables])
        puts "Creating configuration file..."
        File.open("#{project_name}.yml", "w") do |f|
            f.write(opts.to_yaml)
        end
        puts "Successfully completed!"
        start_server(db)
    end

    map "-S" => "server"
    desc "server FILE", "Starts the AutoREST API server using a config file"
    # Starts the AutoREST API server using a configuration file
    # Loads the configuration file and starts the server with the specified database settings.
    def server(file)
        opts = YAML.load_file(file)
        case opts[:db][:kind]
        when :sqlite
            require_relative "autorest/db/sqlite"
            db = AutoREST::SQLiteDB.new(opts[:db][:name])
        when :mysql
            require_relative "autorest/db/mysql"
            db = AutoREST::MySQLDB.new(opts[:db][:host], opts[:db][:port], opts[:db][:user], opts[:db][:passwd], opts[:db][:name])
        when :pg
            require_relative "autorest/db/postgres"
            db = AutoREST::PostgresDB.new(opts[:db][:host], opts[:db][:port], opts[:db][:user], opts[:db][:passwd], opts[:db][:name])
        when :orcl
            require_relative "autorest/db/oracle"
            db = AutoREST::OracleDB.new(opts[:db][:host], opts[:db][:port], opts[:db][:user], opts[:db][:passwd], opts[:db][:name])
        end
        db.prepare
        db.set_access_tables(opts[:db][:tables])
        servinfo = opts.fetch(:server, { host: "localhost", port: 7914})
        start_server(db, servinfo[:host], servinfo[:port])
    end

    map "-s" => "boot"
    desc "boot DSN", "Starts the AutoREST API server using a DSN"
    # Starts the AutoREST API server using a DSN (Data Source Name)
    # Parses the DSN and starts the server using the corresponding database.
    def boot(dsn)
        uri = URI.parse(dsn)
        if uri.scheme == "sqlite"
            require_relative "autorest/db/sqlite"
            db = AutoREST::SQLiteDB.new(uri.host)
            table, *_ = uri.path.sub(/^\//, '').split('/')
        else
            database, table = uri.path.sub(/^\//, '').split('/')
            passwd = URI.decode_www_form_component(uri.password)
            case uri.scheme
            when "mysql"
                require_relative "autorest/db/mysql"
                db = AutoREST::MySQLDB.new(uri.host, uri.port, uri.user, passwd, database)
            when "pg"
                require_relative "autorest/db/postgres"
                db = AutoREST::PostgresDB.new(uri.host, uri.port, uri.user, passwd, database)
            when "orcl"
                require_relative "autorest/db/oracle"
                db = AutoREST::OracleDB.new(uri.host, uri.port, uri.user, passwd, database)
            end
        end
        db.prepare
        db.set_access_tables([table])
        start_server(db)
    end

    no_commands do
        # Starts the AutoREST server
        def start_server(db, host = "localhost", port = 7914)
            server = AutoREST::Server.new(db)
            puts "Starting server..."
            Rack::Handler::Puma.run(server, Host: host, Port: port)
            db.close
        end
    end
end