# encoding: utf-8

require "java"

# local dev setup
classes_dir = File.expand_path("../../../out/production/main", __FILE__)

if File.directory?(classes_dir)
  # if in local dev setup, add to classpath
  $CLASSPATH << classes_dir unless $CLASSPATH.include?(classes_dir)
else
  # otherwise use included jar
  require_relative "jruby_event.jar"
end
require_relative "jackson-core-asl-1.9.13.jar"
require_relative "jackson-mapper-asl-1.9.13.jar"

require "jruby_event_ext"
require "jruby_timestamp_ext"