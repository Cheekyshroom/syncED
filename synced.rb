#!/usr/bin/env ruby
require_relative "server"
require_relative "client"

def run_client

end

def run_server
   server = Server.new
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
