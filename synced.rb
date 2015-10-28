#!/usr/bin/env ruby
require "pstore"
require "socket"

class Cfg
   @@default_name = "data/config.pstore"
   def initialize(filename=nil)
      if filename then
         @data = PStore.new(filename)
      else
         @data = PStore.new(@@default_name)
         @data.transaction do 
            @data["users"] = []
            @data["port"] = 12345
            @data["name"] = "Unnamed server!"
         end
      end
   end
   def get(name)
      @data.transaction { @data[name] }
   end
end

class Server
   def initialize(config)
      @config = config
      @connections = []
      @socket = TCPServer.new(@config.get("port"))
      c = @socket.accept
      c.puts("Hello")
      loop do
         i = c.gets.chomp
         c.puts(@config.get(i))
         break if i == "quit"
      end
      c.close
   end
end

def run_client

end

def run_server
   config_exists = Dir.exist?("data")
   Dir.mkdir("data") unless config_exists
   config = config_exists ? Cfg.new("data/config.pstore") : Cfg.new
   server = Server.new(config)
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
