require "socket"
require "pstore"
require_relative "connection"

class Server
   @@dirs_that_should_exist = ["data", "data/files"]
   @@default_config_name = "data/config.pstore"
   def initialize
      config_exists = true
      @@dirs_that_should_exist.each do |dir|
         unless Dir.exist?(dir)
            Dir.mkdir(dir)
            config_exists = false
         end
      end
      @config = PStore.new(@@default_config_name)
      unless config_exists
         @config.transaction do 
            @config["users"] = {}
            @config["port"] = 12345
            @config["name"] = "Unnamed server!"
         end
      end
      @connections = []
      @socket = TCPServer.new(get_config("port"))
      @users = []
   end
   def handle_connection
      user = Connection.new(@socket.accept, @users.length, self)
      @users << user
      user.handle
   end
   def get_config(name)
      @config.transaction { @config[name] }
   end
   def add_user_to_config(name)
      @config.transaction { @config["users"][name] = true }
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
