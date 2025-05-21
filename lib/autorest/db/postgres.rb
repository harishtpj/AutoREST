# DB Adapter for PostgreSQL database
require "pg"

require_relative "adapter"

class AutoREST::PostgresDB < AutoREST::DBAdapter
    def initialize(host, port, user, passwd, dbname)
        conn = PG.connect(host: host, port: port, user: user, password: passwd, dbname: dbname)
        super(:pg, dbname, conn)
    end

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

    def exec_sql(sql)
        @db_conn.exec(sql).to_a
    end
end