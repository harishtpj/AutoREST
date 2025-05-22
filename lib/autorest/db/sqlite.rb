# DB Adapter for SQLite database
require "sqlite3"

require_relative "adapter"

class AutoREST::SQLiteDB < AutoREST::DBAdapter
    def initialize(dbname)
        conn = SQLite3::Database.new(dbname)
        conn.results_as_hash = true
        super(:sqlite, dbname, conn)
    end

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

    def exec_sql(sql)
        @db_conn.execute(sql)
    end

    def escape(input)
        SQLite3::Database.quote(input)
    end
end