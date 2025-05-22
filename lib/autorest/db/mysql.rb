# DB Adapter for MySQL database
begin
    require "mysql2"
rescue LoadError
    warn "Please install the 'mysql2' gem to use MySQL database."
end

require_relative "adapter"

# MySQL adapter for AutoREST.
#
# Uses the `mysql2` gem to connect and interact with a MySQL database.
# Automatically detects tables and primary key columns.
#
# @example Initialize adapter
#   db = AutoREST::MySQLDB.new("localhost", 3306, "root", "password", "mydb")
#
class AutoREST::MySQLDB < AutoREST::DBAdapter

    # @param host [String] Hostname of the MySQL server
    # @param port [Integer] Port number
    # @param user [String] Username
    # @param passwd [String] Password
    # @param dbname [String] Name of the MySQL database
    def initialize(host, port, user, passwd, dbname)
        conn = Mysql2::Client.new(host: host, port: port, username: user, password: passwd, database: dbname)
        super(:mysql, dbname, conn)
    end

    # Loads table metadata including columns and primary keys.
    # @return [void]
    def prepare
        @tables = {}
        @db_conn.query("show tables").each do |t|
            tname = t["Tables_in_#{@dbname}"]
            row_details = @db_conn.query("desc #{tname}")
            @tables[tname] = {}
            row_details.each do |row|
                @tables[tname][row["Field"]] = {type: row["Type"], pk: row["Key"] == "PRI"}
            end
        end
    end

    # Executes a raw SQL query.
    # @param sql [String] The SQL query to run
    # @return [Array<Hash>] Resulting rows
    def exec_sql(sql)
        @db_conn.query(sql).to_a
    end

    # Escapes identifiers or values for safe usage in queries.
    # @param input [String] Table or column name
    # @return [String] Escaped string
    def escape(input)
        @db_conn.escape(input)
    end
end