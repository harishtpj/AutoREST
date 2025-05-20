# The main executable for AutoREST
require "thor"

require_relative "autorest/version"

class AutoREST::CLI < Thor
    desc "version", "Prints the version of AutoREST"
    def version
        puts "AutoREST v#{AutoREST::VERSION}"
    end
end