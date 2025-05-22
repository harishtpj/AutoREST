# DB Adapter for PostgreSQL database
begin
    require "pg"
rescue LoadError
    warn "Please install the 'pg' gem to use PostgreSQL database."
end

require_relative "adapter"

# PostgreSQL adapter for AutoREST.
#
# Uses the `pg` gem to connect and interact with a PostgreSQL database.
# Detects tables and their primary keys by querying PostgreSQL system catalogs.
#
# @example Initialize adapter
#   db = AutoREST::PostgresDB.new("localhost", 5432, "postgres", "secret", "mydb")
#
class AutoREST::PostgresDB < AutoREST::DBAdapter

    # @param host [String] Hostname of the PostgreSQL server
    # @param port [Integer] Port number
    # @param user [String] Username
    # @param passwd [String] Password
    # @param dbname [String] Name of the PostgreSQL database
    def initialize(host, port, user, passwd, dbname)
        conn = PG.connect(host: host, port: port, user: user, password: passwd, dbname: dbname)
        super(:pg, dbname, conn)
    end

    # Loads table metadata including columns and primary keys.
    #
    # It excludes system tables by filtering out `pg_catalog` and `information_schema` schemas.
    #
    # @return [void]
    def prepare
        desc_query = <<-SQL
        SELECT
            a.attname AS cname,
            pg_catalog.format_type(a.atttypid, a.atttypmod) AS dtype,
            coalesce(i.indisprimary, false) AS pk
        FROM
            pg_catalog.pg_attribute a
        JOIN pg_catalog.pg_class c ON a.attrelid = c.oid
        JOIN pg_catalog.pg_namespace n ON c.relnamespace = n.oid
        LEFT JOIN pg_catalog.pg_index i
            ON c.oid = i.indrelid
            AND a.attnum = ANY(i.indkey)
            AND i.indisprimary
        WHERE
            c.relname = $1
            AND a.attnum > 0
            AND NOT a.attisdropped
        ORDER BY a.attnum;
        SQL
        @tables = {}
        @db_conn.exec("SELECT tablename FROM pg_catalog.pg_tables
        WHERE schemaname NOT IN ('pg_catalog', 'information_schema')").each do |t|
            tname = t["tablename"]
            row_details = @db_conn.exec_params(desc_query, [tname])
            @tables[tname] = {}
            row_details.each do |row|
                @tables[tname][row["cname"]] = {type: row["type"], pk: row["pk"]}
            end
        end
    end

    # Executes a raw SQL query.
    # @param sql [String] The SQL query to run
    # @return [Array<Hash>] Resulting rows
    def exec_sql(sql)
        @db_conn.exec(sql).to_a
    end

    # Escapes a string input to safely use in SQL queries.
    # @param input [String] Raw user input
    # @return [String] Escaped string
    def escape(input)
        @db_conn.escape_string(input)
    end
end