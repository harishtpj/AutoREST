# Table Base class

class AutoREST::DB
    attr_reader :dbname
    def initialize(db_kind, db_name, db_conn)
        @db_kind = db_kind
        @dbname = dbname
        @db_conn = db_conn
    end

    def get_tables
        @db_conn.execute("SELECT name FROM sqlite_master WHERE type='table'")
    end

    def get_columns(table_name)
        @db_conn.execute("select name, type, pk from pragma_table_info('#{table_name}')")
    end
end