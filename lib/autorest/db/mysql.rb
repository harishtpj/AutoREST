# DB Adapter for MySQL database
require "mysql2"

require_relative "adapter"

class AutoREST::MySQLDB < AutoREST::DBAdapter
    def initialize(host, port, user, passwd, dbname)
        conn = Mysql2::Client.new(host: host, port: port, username: user, password: passwd, database: dbname)
        super(:mysql, dbname, conn)
    end

    def prepare
        @tables = {}
        @db_conn.query("show tables").each do |t|
            tname = t["Tables_in_#{@dbname}"]
            row_details = @db_conn.query("desc #{tname}")
            @tables[tname] = {}
            row_details.each do |row|
                @tables[tname][row["Field"]] = {type: row["Type"], pk: row["Key"] == "PRI"}
            end
        end
    end

    def exec_sql(sql)
        @db_conn.query(sql).to_a
    end
end