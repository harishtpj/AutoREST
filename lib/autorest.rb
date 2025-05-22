# The main executable for AutoREST
require "thor"
require "tty-prompt"
require "rack"
require "rack/handler/puma"
require "yaml"
require "uri"

require_relative "autorest/version"
require_relative "autorest/server"
require_relative "autorest/db/sqlite"
require_relative "autorest/db/mysql"
require_relative "autorest/db/postgres"
require_relative "autorest/db/oracle"

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
        opts = {db: {}, server: { host: "localhost", port: 7914 } }
        puts "Welcome to AutoREST API Server Generator"
        project_name = prompt.ask("Enter the project's name:")
        opts[:db][:kind] = prompt.select("Select your database:",
                                {"SQLite" => :sqlite, "MySQL" => :mysql, "PostgreSQL" => :pg, "Oracle" => :orcl}, 
                                default: "SQLite")

        if opts[:db][:kind] == :sqlite
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
                db = AutoREST::MySQLDB.new(opts[:db][:host], opts[:db][:port], opts[:db][:user], opts[:db][:passwd], opts[:db][:name])
            when :pg
                db = AutoREST::PostgresDB.new(opts[:db][:host], opts[:db][:port], opts[:db][:user], opts[:db][:passwd], opts[:db][:name])
            when :orcl
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
    desc "server FILE", "Starts the AutoREST API server using a configuration file"
    def server(file)
        opts = YAML.load_file(file)
        if opts[:db][:kind] == :sqlite
            db = AutoREST::SQLiteDB.new(opts[:db][:name])
        else
            case opts[:db][:kind]
            when :mysql
                db = AutoREST::MySQLDB.new(opts[:db][:host], opts[:db][:port], opts[:db][:user], opts[:db][:passwd], opts[:db][:name])
            when :pg
                db = AutoREST::PostgresDB.new(opts[:db][:host], opts[:db][:port], opts[:db][:user], opts[:db][:passwd], opts[:db][:name])
            when :orcl
                db = AutoREST::OracleDB.new(opts[:db][:host], opts[:db][:port], opts[:db][:user], opts[:db][:passwd], opts[:db][:name])
            end
        end
        db.prepare
        db.set_access_tables(opts[:db][:tables])
        servinfo = opts.fetch(:server, { host: "localhost", port: 7914})
        start_server(db, servinfo[:host], servinfo[:port])
    end

    map "-s" => "boot"
    desc "boot DSN", "Starts the AutoREST API server using a DSN"
    def boot(dsn)
        uri = URI.parse(dsn)
        if uri.scheme == "sqlite"
            db = AutoREST::SQLiteDB.new(uri.host)
            table, *_ = uri.path.sub(/^\//, '').split('/')
        else
            database, table = uri.path.sub(/^\//, '').split('/')
            passwd = URI.decode_www_form_component(uri.password)
            case uri.scheme
            when "mysql"
                db = AutoREST::MySQLDB.new(uri.host, uri.port, uri.user, passwd, database)
            when "pg"
                db = AutoREST::PostgresDB.new(uri.host, uri.port, uri.user, passwd, database)
            when "orcl"
                db = AutoREST::OracleDB.new(uri.host, uri.port, uri.user, passwd, database)
            end
        end
        db.prepare
        db.set_access_tables([table])
        start_server(db)
    end

    no_commands do
        def start_server(db, host = "localhost", port = 7914)
            server = AutoREST::Server.new(db)
            puts "Starting server..."
            Rack::Handler::Puma.run(server, Host: host, Port: port)
            db.close
        end
    end
end