#!/usr/bin/env ruby
require "socket"
require_relative "cfg"
require_relative "connection"

class Server
   def initialize(config)
      @config = config
      @connections = []
      @socket = TCPServer.new(@config.get("port"))
      @users = []
   end
   def handle_connection
      user = Connection.new(@socket.accept, @users.length)
      @users << user
      user.handle
   end
   def run
      puts("Starting server.")
      begin
        loop { handle_connection }
      rescue Interrupt => e
         puts("\rClosing server.")
      end
   end
end

def run_client

end

def run_server
   config_exists = Dir.exist?("data")
   Dir.mkdir("data") unless config_exists
   config = config_exists ? Cfg.new("data/config.pstore") : Cfg.new
   server = Server.new(config)
   server.run
end

$type, = ARGV
case $type
when "connect" then
   run_client
when "host" then
   run_server
else
   run_server
end
