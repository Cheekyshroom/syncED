#!/usr/bin/env ruby
require "pstore"
require "socket"

def run_client
   puts("Client.")
end

def run_server
   puts("Server.")
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
