# encoding: utf-8

require "java"

module LogStash
end

# local dev setup
classes_dir = File.expand_path("../../../build/classes/main", __FILE__)

if File.directory?(classes_dir)
  # if in local dev setup, add target to classpath
  $CLASSPATH << classes_dir unless $CLASSPATH.include?(classes_dir)
else
  # otherwise use included jar
  begin
    raise("no jar")
    # require "logstash-core-event-java/logstash-core-event-java.jar"
  rescue Exception => e
    raise("Error loading logstash-core java, cause: #{e.message}")
  end
end
