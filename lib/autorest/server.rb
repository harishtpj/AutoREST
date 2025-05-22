# The main server instance for AutoREST
require "sinatra/base"

class AutoREST::Server < Sinatra::Base
    def initialize(db_conn)
        super()
        @db_conn = db_conn
    end

    before do
        content_type :json
    end

    helpers do
        def error(msg, status = 400)
            halt status, { error: msg }.to_json
        end

        def get_body(req)
            req.body.rewind
            JSON.parse(req.body.read)
        end
    end

    get '/' do
        { message: "Welcome to AutoREST API Server" }.to_json
    end

    get '/:table/?' do |tname|
        cols = params["only"] || "*"
        q = @db_conn.rows(tname, cols)
        if q.is_a?(String)
            code, msg = q.split(": ", 2)
            error(msg, code.to_i)
        end
        q.to_json
    end

    post '/:table/?' do |tname|
        data = get_body(request)
        error("Incomplete request body") if data.empty?
        q = @db_conn.insert(tname, data)
        if q.is_a?(String)
            code, msg = q.split(": ", 2)
            error(msg, code.to_i)
        end
        q.to_json
    end

    get '/:table/:pk/?' do |tname, pk|
        cols = params["only"] || "*"
        pk = pk.match?(/\A-?\d+(\.\d+)?\z/) ? pk.to_i : pk
        q = @db_conn.row(tname, pk, cols)
        if q.is_a?(String)
            code, msg = q.split(": ", 2)
            error(msg, code.to_i)
        end
        q.to_json
    end

    put '/:table/:pk/?' do |tname, pk|
        data = get_body(request)
        error("Incomplete request body") if (data.empty? || data.keys != @db_conn.columns(tname))
        pk = pk.match?(/\A-?\d+(\.\d+)?\z/) ? pk.to_i : pk
        q = @db_conn.update(tname, pk, data)
        if q.is_a?(String)
            code, msg = q.split(": ", 2)
            error(msg, code.to_i)
        end
        q.to_json
    end

    patch '/:table/:pk/?' do |tname, pk|
        data = get_body(request)
        error("Incomplete request body") if data.empty?
        pk = pk.match?(/\A-?\d+(\.\d+)?\z/) ? pk.to_i : pk
        q = @db_conn.update(tname, pk, data, true)
        if q.is_a?(String)
            code, msg = q.split(": ", 2)
            error(msg, code.to_i)
        end
        q.to_json
    end

    delete '/:table/:pk/?' do |tname, pk|
        pk = pk.match?(/\A-?\d+(\.\d+)?\z/) ? pk.to_i : pk
        q = @db_conn.del_row(tname, pk)
        if q.is_a?(String)
            code, msg = q.split(": ", 2)
            error(msg, code.to_i)
        end
        q.to_json
    end

    error 500 do
        { error: "Internal Server Error" }.to_json
    end
end