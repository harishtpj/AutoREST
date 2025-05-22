# DB Adapter for Oracle database
begin
    ENV['NLS_LANG'] ||= 'AMERICAN_AMERICA.US7ASCII'
    require "oci8"
rescue LoadError
    warn "Please install the 'ruby-oci8' gem to use Oracle database."
end

require_relative "adapter"

# Oracle DB adapter for AutoREST.
#
# Uses the `oci8` gem to connect and interact with an Oracle database.
# Retrieves tables and primary key details from Oracle's user-owned tables and constraints.
#
# @example Initialize adapter
#   db = AutoREST::OracleDB.new("localhost", 1521, "sys", "secret", "ORCL")
#
class AutoREST::OracleDB < AutoREST::DBAdapter

    # @param host [String] Hostname of the Oracle server
    # @param port [Integer] Port number
    # @param user [String] Username
    # @param passwd [String] Password
    # @param sid [String] Oracle SID (System Identifier)
    def initialize(host, port, user, passwd, sid)
        conn = OCI8.new(user, passwd, "//#{host}:#{port}/#{sid}")
        conn.autocommit = true
        super(:orcl, sid, conn)
    end

    # Loads table metadata including columns and primary keys.
    #
    # Queries Oracle's `user_tab_columns` and `user_cons_columns` system views to get
    # the column details and primary key information.
    #
    # @return [void]
    def prepare
        desc_query = <<~SQL
        SELECT c.column_name,
                c.data_type,
                CASE WHEN pk.pk_column IS NOT NULL THEN 'YES' ELSE 'NO' END AS primary_key
        FROM user_tab_columns c
        LEFT JOIN (
            SELECT ucc.column_name AS pk_column
            FROM user_cons_columns ucc
            JOIN user_constraints uc
            ON ucc.constraint_name = uc.constraint_name
            WHERE uc.constraint_type = 'P'
            AND uc.table_name = :1
        ) pk ON c.column_name = pk.pk_column
        WHERE c.table_name = :1
        SQL

        @tables = {}
        @db_conn.exec("select * from cat") do |t|
            tname = t[0]
            @tables[tname] = {}
            @db_conn.exec(desc_query, tname) do |row|
                @tables[tname][row[0]] = {type: row[1], pk: row[2] == "YES"}
            end
        end
    end

    # Executes a raw SQL query.
    # @param sql [String] The SQL query to run
    # @return [Array<Hash>] Resulting rows
    def exec_sql(sql)
        cursor = @db_conn.exec(sql)
        cols = cursor.get_col_names
        res = []
        while row = cursor.fetch
            res << Hash[cols.zip(row)]
        end
        res
    end

    # Closes the database connection.
    # @return [void]
    def close
        @db_conn.logoff
    end

    # Escapes a string input to safely use in SQL queries.
    # @param input [String] Raw user input
    # @return [String] Escaped string
    def escape(input)
        input.to_s.gsub("'", "''")
    end
end