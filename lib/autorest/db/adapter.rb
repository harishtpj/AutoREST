# Database Adapter class for AutoREST.
#
# This abstract class serves as a base class for specific database adapters such as
# SQLite, MySQL, PostgreSQL, and Oracle. It defines the common interface that all
# adapters must implement. These include methods for preparing the database (e.g., 
# fetching table and column metadata), executing SQL queries, and managing database
# connections.
#
# @abstract
class AutoREST::DBAdapter

    # Initializes a new DBAdapter instance.
    #
    # @param db_kind [Symbol] The type of database (e.g., :sqlite, :mysql, :pg, :orcl)
    # @param db_name [String] The database name or SID (for Oracle)
    # @param db_conn [Object] The database connection object
    def initialize(db_kind, db_name, db_conn)
        @db_kind = db_kind
        @dbname = db_name
        @db_conn = db_conn
        @tables = nil
    end

    # Prepares the database by fetching metadata, such as tables and columns.
    # This method must be implemented by subclasses.
    #
    # @raise [NotImplementedError] If the method is not implemented by a subclass.
    # @abstract
    def prepare
        raise NotImplementedError, "#{self.class} has not implemented method '#{__method__}'"
    end

    # Executes a raw SQL query.
    #
    # @param sql [String] The SQL query to execute
    # @return [Array<Hash>] The result of the query as an array of hashes
    # @abstract
    def exec_sql(sql)
        raise NotImplementedError, "#{self.class} has not implemented method '#{__method__}'"
    end

    # Escapes input data to safely use in SQL queries.
    #
    # @param input [String] The raw input data
    # @return [String] The escaped input data
    # @abstract
    def escape(input)
        raise NotImplementedError, "#{self.class} has not implemented method '#{__method__}'"
    end

    # Sets the access tables for the database. If no tables are specified, all tables are accessible.
    #
    # @param access_tab [Array<String>] A list of tables the user has access to
    # @return [void]
    def set_access_tables(access_tab)
        @access_tables = access_tab.empty? ? @tables.keys : access_tab
    end

    # Returns the list of table names in the database.
    #
    # @return [Array<String>] A list of table names
    def tables
        prepare if @tables.nil?
        @tables.keys
    end

    # Returns the list of column names for a given table.
    #
    # @param table_name [String] The name of the table
    # @return [Array<String>] A list of column names
    def columns(table_name)
        prepare if @tables.nil?
        @tables[table_name].keys
    end

    # Returns the rows of a table for the specified columns.
    #
    # @param table_name [String] The name of the table
    # @param cols [String, Array<String>] The columns to retrieve (defaults to "*")
    # @return [Array<Hash>, String] The rows of the table as an array of hashes, or an error message
    def rows(table_name, cols = "*")
        prepare if @tables.nil?
        return "404: Table #{table_name} does not exist" unless @tables.include?(table_name)
        return "403: Insufficient rights to access Table #{table_name}" unless @access_tables.include?(table_name)
        result = exec_sql("select #{escape(cols)} from #{escape(table_name)}")
        return "404: Table #{table_name} is empty" if result.empty?
        result
    end

    # Returns a specific row in a table identified by its primary key value.
    #
    # @param table_name [String] The name of the table
    # @param value [String, Integer] The value of the primary key
    # @param cols [String, Array<String>] The columns to retrieve (defaults to "*")
    # @return [Hash, String] The row as a hash, or an error message
    def row(table_name, value, cols = "*")
        prepare if @tables.nil?
        return "404: Table #{table_name} does not exist" unless @tables.include?(table_name)
        return "403: Insufficient rights to access Table #{table_name}" unless @access_tables.include?(table_name)
        return "502: Table does not have primary key" if pkey(table_name).nil?
        result = exec_sql("select #{escape(cols)} from #{table_name} where #{pkey(table_name)} = #{value.inspect}")
        return "404: Row not found" if result.empty?
        result
    end

    # Inserts a new row into a table.
    #
    # @param table_name [String] The name of the table
    # @param data [Hash] The data to insert, where keys are column names and values are column values
    # @return [Hash, String] The inserted row as a hash, or an error message
    def insert(table_name, data)
        prepare if @tables.nil?
        return "404: Table #{table_name} does not exist" unless @tables.include?(table_name)
        return "403: Insufficient rights to access Table #{table_name}" unless @access_tables.include?(table_name)
        return "409: Row already exists" if has_row(table_name, data[pkey(table_name)])
        cols = data.keys.join(", ")
        values = data.values.map(&:inspect).join(", ")
        exec_sql("insert into #{escape(table_name)} (#{cols}) values (#{values})")
        row(table_name, data[pkey(table_name)])
    end

    # Updates an existing row in a table.
    #
    # @param table_name [String] The name of the table
    # @param pk [String, Integer] The primary key of the row to update
    # @param value [Hash] The new values for the row, where keys are column names and values are column values
    # @param patch [Boolean] If true, allows the partial changes, for PATCH requests (defaults to false)
    # @return [Hash, String] The updated row as a hash, or an error message
    def update(table_name, pk, value, patch = false)
        prepare if @tables.nil?
        return "404: Table #{table_name} does not exist" unless @tables.include?(table_name)
        return "403: Insufficient rights to update Table #{table_name}" unless @access_tables.include?(table_name)
        return "404: Row not found" unless has_row(table_name, pk)
        return "422: Primary key mismatch" if (pk != value[pkey(table_name)].to_s && !patch)
        return "422: Invalid data" if (value.keys & columns(table_name) != value.keys)
        kvpairs = value.map { |k, v| "#{k} = #{v.inspect}" }.join(", ")
        exec_sql("update #{escape(table_name)} set #{kvpairs} where #{pkey(table_name)} = #{pk.inspect}")
        row(table_name, pk)
    end

    # Deletes a row from a table.
    #
    # @param table_name [String] The name of the table
    # @param value [String, Integer] The value of the primary key of the row to delete
    # @return [Hash, String] The deleted row as a hash, or an error message
    def del_row(table_name, value)
        prepare if @tables.nil?
        return "404: Table #{table_name} does not exist" unless @tables.include?(table_name)
        return "403: Insufficient rights to delete Table #{table_name}" unless @access_tables.include?(table_name)
        result = row(table_name, value)
        return result if result.is_a?(String)
        exec_sql("delete from #{escape(table_name)} where #{pkey(table_name)} = #{value.inspect}")
        result
    end

    # Closes the database connection.
    #
    # @return [void]
    def close
        @db_conn.close
    end

    private
        # Returns the primary key column name for a given table.
        #
        # @param table_name [String] The name of the table
        # @return [String, nil] The primary key column name, or nil if no primary key exists
        def pkey(table_name)
            @tables[table_name].keys.find { |k| @tables[table_name][k][:pk] }
        end

        # Checks if a row exists in the table based on the primary key value.
        #
        # @param table_name [String] The name of the table
        # @param value [String, Integer] The value of the primary key
        # @return [Boolean] True if the row exists, false otherwise
        def has_row(table_name, value)
            !row(table_name, value).is_a?(String)
        end
end