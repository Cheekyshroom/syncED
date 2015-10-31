require "socket"
require "thread"
require "base64"

class Connection
   attr_reader :thread, :username
   def initialize(socket, id, server)
      @thread = nil
      @socket = socket
      @id = id
      @thread = Thread.new do
         @socket.puts("Welcome to syncED, please enter your username")
         @username = @socket.gets.chomp
         @sanitized_name = sanitize(@username) #sanitize their username for later
         dir = "data/files/#{@sanitized_name}/"
         Dir.mkdir(dir) unless Dir.exist?(dir)
         server.add_user_to_config(@username)
      end
   end
   def handle
      thread = Thread.new do
         puts("Handling user #{@username}.")
         @thread.join #make sure that we've got our username first
         @thread = thread #if we have, make this the main thread for this connection

         loop do #main user interaciton loop
            @socket.puts("Send a message with your decision:")
            @socket.puts("'list' to list currently owned files,")
            @socket.puts("'new' to upload a new file,")
            @socket.puts("'remove' to remove a file,")
            @socket.puts("and 'download' to download a certain file") #used in combination with list to sync files
            decision = @socket.gets.chomp
            #do nothing right now
         end

         #presumably this connection is over with, get rid of the client's sockets
         #remove this later
         @socket.puts("Bye client \##{@id}")
         @socket.close
      end
   end
   def receive_file
      path = @socket.gets.chomp #read the desired filename from the client
      sanitized_path = sanitize(path) #sanitize it just in case
      if (@sanitized_name) #if we've got a username and it's sanitized
         finalized_path = "data/files/#{@sanitized_name}/#{sanitized_path}"
         size = @socket.gets.chomp.to_i #get the size from the client
         data = @socket.read(size) #get the data from the client (definitely bad for large files)
         File.open(finalized_path, "w") do |f|
            f.write(data) #write that data to a file.
         end
      end
   end
   def sanitize(name)
      Base64.urlsafe_encode64(name)
   end
end
