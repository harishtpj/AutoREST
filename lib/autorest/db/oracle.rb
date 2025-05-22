# DB Adapter for Oracle database
ENV['NLS_LANG'] ||= 'AMERICAN_AMERICA.US7ASCII'
require "oci8"

require_relative "adapter"

class AutoREST::OracleDB < AutoREST::DBAdapter
    def initialize(host, port, user, passwd, sid)
        conn = OCI8.new(user, passwd, "//#{host}:#{port}/#{sid}")
        conn.autocommit = true
        super(:orcl, sid, conn)
    end

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

    def exec_sql(sql)
        cursor = @db_conn.exec(sql)
        cols = cursor.get_col_names
        res = []
        while row = cursor.fetch
            res << Hash[cols.zip(row)]
        end
        res
    end

    def close
        @db_conn.logoff
    end

    def escape(input)
        input.to_s.gsub("'", "''")
    end
end