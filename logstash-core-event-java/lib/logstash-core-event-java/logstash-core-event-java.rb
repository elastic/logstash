# encoding: utf-8

require "java"

module LogStash
end

# TODO: (colin) integrate jar loading with gradle and verify dev vs prod environment setups

# insert all jars in this directory into CLASSPATH
Dir.glob(File.join(File.expand_path("..", __FILE__), "*.jar")).each do |jar|
  $CLASSPATH << jar unless $CLASSPATH.include?(jar)
end

# TODO: (colin) correctly handle dev env build/ dir and local jar

# local dev setup
classes_dir = File.expand_path("../../../build/classes/main", __FILE__)

if File.directory?(classes_dir)
  # if in local dev setup, add target to classpath
  $CLASSPATH << classes_dir unless $CLASSPATH.include?(classes_dir)
else
  # otherwise use included jar
  raise("TODO build dir not found and no jar file")
end

require "jruby_event_ext"
require "jruby_timestamp_ext"
require "logstash/event"
require "logstash/timestamp"