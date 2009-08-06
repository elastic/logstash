#!/usr/bin/ruby

require 'rubygems'
require 'json'
require 'socket'


log_name = ARGV[0]
log_path = ARGV[1] || "/dev/stdin"
source_host = %x(hostname).chomp

if not log_name
  $stderr.puts "usage: import.rb log_name [path]"
  exit 1
end

sock = TCPSocket.new('127.0.0.1', 12345)
size = 0
start_t = Time.now.to_f
File.open(log_path).each do |line|
  msg = {"log_name" => log_name,
         "raw_entry" => line,
         "source_host" => source_host,
        }
  sock.puts msg.to_json
  size += line.length
end
end_t = Time.now.to_f
sock.close

size /= 1024.0  # kB
puts "import rate: #{size/(end_t-start_t)} kB/s"
