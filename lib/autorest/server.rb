# The main server instance for AutoREST
require "sinatra/base"

class AutoREST::Server < Sinatra::Base
    def initialize(db_conn, tables)
        super()
        @db_conn = db_conn
    end

    before do
        content_type :json
    end

    get '/' do
        { message: "Welcome to AutoREST API Server" }.to_json
    end

    get '/:table' do |tname|
        @db_conn.rows(tname).to_json
    end

    get '/:table/:pk' do |tname, pk|
        @db_conn.row(tname, pk).to_json
    end

    delete '/:table/:pk' do |tname, pk|
        @db_conn.del_row(tname, pk)
    end
end