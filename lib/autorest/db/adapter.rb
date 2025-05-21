# Database Adapter to provide access to data from database

class AutoREST::DBAdapter

    def initialize(db_kind, db_name, db_conn)
        @db_kind = db_kind
        @dbname = db_name
        @db_conn = db_conn
        @tables = nil
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

    def tables
        prepare if @tables.nil?
        @tables.keys
    end

    def columns(table_name)
        prepare if @tables.nil?
        @tables[table_name].keys
    end

    def rows(table_name, cols = "*")
        prepare if @tables.nil?
        @db_conn.execute("select #{cols} from #{table_name}")
    end

    def row(table_name, value, cols = "*")
        prepare if @tables.nil?
        @db_conn.execute("select #{cols} from #{table_name} where #{pkey(table_name)} = '#{value}'")
    end

    def del_row(table_name, value)
        prepare if @tables.nil?
        @db_conn.execute("delete from #{table_name} where #{pkey(table_name)} = '#{value}'")
    end

    private
        def pkey(table_name)
            @tables[table_name].keys.find { |k| @tables[table_name][k][:pk] }
        end
end