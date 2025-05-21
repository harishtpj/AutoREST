# Database Adapter to provide access to data from database

class AutoREST::DBAdapter
    def initialize(db_kind, db_name, db_conn)
        @db_kind = db_kind
        @dbname = db_name
        @db_conn = db_conn
        @tables = nil
    end

    def prepare
        raise NotImplementedError, "#{self.class} has not implemented method '#{__method__}'"
    end

    def set_access_tables(access_tab)
        @access_tables = access_tab.empty? ? @tables.keys : access_tab
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
        return "404: Table #{table_name} does not exist" unless @tables.include?(table_name)
        return "403: Insufficient rights to access Table #{table_name}" unless @access_tables.include?(table_name)
        result = @db_conn.execute("select #{cols} from #{table_name}")
        return "404: Table #{table_name} is empty" if result.empty?
        result
    end

    def row(table_name, value, cols = "*")
        prepare if @tables.nil?
        return "404: Table #{table_name} does not exist" unless @tables.include?(table_name)
        return "403: Insufficient rights to access Table #{table_name}" unless @access_tables.include?(table_name)
        result = @db_conn.execute("select #{cols} from #{table_name} where #{pkey(table_name)} = '#{value}'")
        return "404: Row not found" if result.empty?
        result
    end

    def insert(table_name, data)
        prepare if @tables.nil?
        return "404: Table #{table_name} does not exist" unless @tables.include?(table_name)
        return "403: Insufficient rights to access Table #{table_name}" unless @access_tables.include?(table_name)
        has_row = !row(table_name, data[pkey(table_name)]).is_a?(String)
        return "409: Row already exists" if has_row
        cols = data.keys.join(", ")
        values = data.values.map(&:inspect).join(", ")
        @db_conn.execute("insert into #{table_name} (#{cols}) values (#{values})")
        row(table_name, data[pkey(table_name)])
    end

    def del_row(table_name, value)
        prepare if @tables.nil?
        return "404: Table #{table_name} does not exist" unless @tables.include?(table_name)
        return "403: Insufficient rights to delete Table #{table_name}" unless @access_tables.include?(table_name)
        result = row(table_name, value)
        return result if result.is_a?(String)
        @db_conn.execute("delete from #{table_name} where #{pkey(table_name)} = '#{value}'")
        result
    end

    private
        def pkey(table_name)
            @tables[table_name].keys.find { |k| @tables[table_name][k][:pk] }
        end
end