require "socket"
require "thread"
require "base64"

class Connection
   attr_reader :thread, :username
   def initialize(socket, id)
      @thread = nil
      @socket = socket
      @id = id
      @thread = Thread.new do
         @socket.puts("Hello client \##{@id}, enter your username: ")
         @username = @socket.gets.chomp
         @sanitized_name = sanitize(@username) #sanitize their username for later
         dir = "data/files/#{@sanitized_name}/"
         Dir.mkdir(dir) unless Dir.exist?(dir)
      end
   end
   def handle
      thread = Thread.new do
         @thread.join #make sure that we've got our username first
         @thread = thread #if we have, make this the main thread for this connection
         #arbitrary test messages
         10.times do |i|
            @socket.puts("Message \##{i} to client #{@id}")
            sleep(1)
         end
         #random file test messages
         receive_file
         #presumably this connection is over with, get rid of the client's sockets
         #remove this later
         @socket.puts("Bye client! #{@id}")
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
