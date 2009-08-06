#!/usr/bin/ruby

require 'rubygems'
require 'ferret'
require 'json'
require 'lib/log/text'
require 'mkdtemp'
require 'socket'

require 'config'

include Ferret

indexes = {}
lines = Hash.new { |h, k| h[k] = 0 }

serv = TCPServer.new(12345)
sock = serv.accept

# Each line in the protocol is a JSON message, with the following fields:
#  log_name ==> key in logs array
#  raw_entry ==> raw entry to parse
sock.each do |line|
  proto = JSON.parse(line)
  pass = true
  ["log_name", "raw_entry"].each do |key|
    next if proto.keys.member?(key)
    $stderr.puts "corrupt packet (#{line.inspect}): missing key #{key}"
    pass = false
    break
  end
  next unless pass
  log_name = proto["log_name"]
  entry = $logs[log_name].parse_entry(proto["raw_entry"])
  next unless entry # or do we stick it in a dummy entry w/just @LINE?
  
  if not indexes.member?(log_name)
    if not File.exists?($logs[log_name].index_dir)
      field_infos = Index::FieldInfos.new(:store => :no,
                                          :term_vector => :no)
      field_infos.add_field(:@LINE,
                            :store => :compressed,
                            :index => :no)
      [:@DATE, :@LOG_NAME, :@SOURCE_HOST].each do |special|
        field_infos.add_field(special,
                              :store => :compressed,
                              :index => :untokenized)
      end
      field_infos.create_index($logs[log_name].index_dir)
    end
    indexes[log_name] = Index::Index.new(:path => $logs[log_name].index_dir)
  end

  # @LINE and @DATE come from Log#parse_entry
  entry["@LOG_NAME"] = log_name
  entry["@SOURCE_HOST"] = 
  indexes[log_name] << entry

  lines[log_name] += 1
  if lines[log_name] % 100 == 0
    indexes[log_name].commit
  end
end

indexes.values.each { |i| i.close }
