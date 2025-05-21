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

    def exec_sql(sql)
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
        result = exec_sql("select #{cols} from #{table_name}")
        return "404: Table #{table_name} is empty" if result.empty?
        result
    end

    def row(table_name, value, cols = "*")
        prepare if @tables.nil?
        return "404: Table #{table_name} does not exist" unless @tables.include?(table_name)
        return "403: Insufficient rights to access Table #{table_name}" unless @access_tables.include?(table_name)
        result = exec_sql("select #{cols} from #{table_name} where #{pkey(table_name)} = '#{value}'")
        return "404: Row not found" if result.empty?
        result
    end

    def insert(table_name, data)
        prepare if @tables.nil?
        return "404: Table #{table_name} does not exist" unless @tables.include?(table_name)
        return "403: Insufficient rights to access Table #{table_name}" unless @access_tables.include?(table_name)
        return "409: Row already exists" if has_row(table_name, data[pkey(table_name)])
        cols = data.keys.join(", ")
        values = data.values.map(&:inspect).join(", ")
        exec_sql("insert into #{table_name} (#{cols}) values (#{values})")
        row(table_name, data[pkey(table_name)])
    end

    def update(table_name, pk, value, patch = false)
        prepare if @tables.nil?
        return "404: Table #{table_name} does not exist" unless @tables.include?(table_name)
        return "403: Insufficient rights to update Table #{table_name}" unless @access_tables.include?(table_name)
        return "404: Row not found" unless has_row(table_name, pk)
        return "422: Primary key mismatch" if (pk != value[pkey(table_name)].to_s && !patch)
        return "422: Invalid data" if (value.keys & columns(table_name) != value.keys)
        kvpairs = value.map { |k, v| "#{k} = #{v.inspect}" }.join(", ")
        exec_sql("update #{table_name} set #{kvpairs} where #{pkey(table_name)} = '#{pk}'")
        row(table_name, pk)
    end

    def del_row(table_name, value)
        prepare if @tables.nil?
        return "404: Table #{table_name} does not exist" unless @tables.include?(table_name)
        return "403: Insufficient rights to delete Table #{table_name}" unless @access_tables.include?(table_name)
        result = row(table_name, value)
        return result if result.is_a?(String)
        exec_sql("delete from #{table_name} where #{pkey(table_name)} = '#{value}'")
        result
    end

    private
        def pkey(table_name)
            @tables[table_name].keys.find { |k| @tables[table_name][k][:pk] }
        end

        def has_row(table_name, value)
            !row(table_name, value).is_a?(String)
        end
end