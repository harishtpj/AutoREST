# DB Adapter for SQLite database
begin
    require "sqlite3"
rescue LoadError
    warn "Please install the 'sqlite3' gem to use SQLite database."
end

require_relative "adapter"

# SQLite adapter for AutoREST.
#
# Uses the `sqlite3` gem to connect and query the SQLite database.
# Automatically discovers tables and primary keys.
#
# @example Initialize adapter
#   db = AutoREST::SQLiteDB.new("data.db")
#
class AutoREST::SQLiteDB < AutoREST::DBAdapter
    
    # @param dbname [String] Path to the SQLite database file
    def initialize(dbname)
        conn = SQLite3::Database.new(dbname)
        conn.results_as_hash = true
        super(:sqlite, dbname, conn)
    end

    # Loads table metadata including columns and primary keys.
    # @return [void]
    def prepare
        @tables = {}
        @db_conn.execute("SELECT name FROM sqlite_master WHERE type='table'").each do |t|
            tname = t['name']
            row_details = @db_conn.execute("select name, type, pk from pragma_table_info('#{tname}')")
            @tables[tname] = {}
            row_details.each do |row|
                @tables[tname][row['name']] = {type: row['type'], pk: row['pk'] == 1}
            end
        end
    end

    # Executes a raw SQL query.
    # @param sql [String] The SQL query to run
    # @return [Array<Hash>] Resulting rows
    def exec_sql(sql)
        @db_conn.execute(sql)
    end

    # Escapes identifiers or values for safe usage in queries.
    # @param input [String] Table or column name
    # @return [String] Escaped string
    def escape(input)
        SQLite3::Database.quote(input)
    end
end