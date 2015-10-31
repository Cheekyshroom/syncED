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
         #make sure that their user folder exists and isn't harmful
         dir = "data/files/#{@sanitized_name}/"
         Dir.mkdir(dir) unless Dir.exist?(dir)
         server.add_user_to_config(@username)
         puts("#{@username} connected.")
      end
   end
   def handle
      thread = Thread.new do
         @thread.join #make sure that we've got our username first
         @thread = thread #if we have, make this the main thread for this connection

         display_help

         loop do #main user interaction loop
            puts("Querying #{@username}")
            decision = @socket.gets.chomp
            case decision #probably make this a hash-table lookup, but not right now
               when "list" then
                  list_files
               when "upload" then
                  receive_file
               when "remove" then

               when "download" then
                  request_send_file
               when "help" then
                  display_help
               when "quit" then
                  break
               else
                  puts("#{@username} entered invalid decision: #{decision}")
            end
         end

         #presumably this connection is over with, get rid of the client's sockets
         #remove this later
         @socket.puts("Bye!")
         @socket.close
      end
   end
   def display_help
      @socket.puts("Send a message with your decision:")
      @socket.puts("'list' to list currently owned files,")
      @socket.puts("'upload' to upload a new file,")
      @socket.puts("'remove' to remove a file,")
      @socket.puts("and")
      @socket.puts("'download' to download a certain file") #used in combination with list to sync files
      @socket.flush
   end
   def receive_file
      puts("Receiving file from: #{@username}.")
      @socket.puts("Give me a filename:")
      @socket.flush
      path = @socket.gets.chomp #read the desired filename from the client
      sanitized_path = sanitize(path) #sanitize it just in case
      if @sanitized_name #if we've got a username and it's sanitized
         finalized_path = "data/files/#{@sanitized_name}/#{sanitized_path}"
         @socket.puts("Give me a filesize:")
         @socket.flush
         size = @socket.gets.chomp.to_i #get the size from the client
         remaining_bytes = size #size left to read
         max_read_size = 8*1024*1024 #max read size is a nice arbirary 8mb
         @socket.puts("Now give me all the data:")
         File.open(finalized_path, "w") do |f|
            while remaining_bytes > 0 #while we have stuff to read
               size_to_read = max_read_size > remaining_bytes ? remaining_bytes : max_read_size
               data = @socket.read(size_to_read) #get the data from the client
               f.write(data) #write that data to a file.
               remaining_bytes -= size_to_read
            end
         end
         @socket.puts("File #{path} successfully received.")
      end
   end
   def request_send_file
      puts("Requesting file from #{@username}.")
      @socket.puts("Give me a filename:")
      @socket.flush
      path = @socket.gets.chomp #receive a file path
      sanitized_path = sanitize(path) #sanitize it
      finalized_path = "data/files/#{@sanitized_name}/#{sanitized_path}" #complete it
      send_file(finalized_path, path) #send the file
   end
   def send_file(safe_path, path)
      puts("Attempting to send file to #{@username}.")
      if @sanitized_name and File.exist?(safe_path)
         @socket.puts("Sending file #{path}")
         size = File.size(safe_path)
         max_write_size = 8*1024*1024 #max write size is a nice arbirary 8mb
         remaining_bytes = size
         File.open(safe_path, "r") do |f|
            while remaining_bytes > 0
               size_to_write = max_write_size > remaining_bytes ? remaining_bytes : max_read_size
               data = f.read(size_to_write)
               @socket.write(data)
               @socket.flush
               remaining_bytes -= size_to_write
            end
         end
         @socket.puts("File #{path} successfully sent.")
      end
   end
   def list_files
      if @sanitized_name
         @socket.puts("Current user files are:")
         user_dir = "data/files/#{@sanitized_name}/"
         Dir.foreach(user_dir) do |filename|
            @socket.puts(unsanitize(filename))
         end
      end
   end
   def sanitize(name)
      Base64.urlsafe_encode64(name)
   end
   def unsanitize(name)
      Base64.urlsafe_decode64(name)
   end
end
