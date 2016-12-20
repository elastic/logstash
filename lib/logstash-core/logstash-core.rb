# encoding: utf-8

require "java"

module LogStash
end

require "logstash-core_jars"

# local dev setup
classes_dir = File.expand_path("../../../build/classes/main", __FILE__)
resources_dir = File.expand_path("../../../build/resources/main", __FILE__)

if File.directory?(classes_dir) && File.directory?(resources_dir)
  # if in local dev setup, add target to classpath
  $CLASSPATH << classes_dir unless $CLASSPATH.include?(classes_dir)
  $CLASSPATH << resources_dir unless $CLASSPATH.include?(resources_dir)
else
  # otherwise use included jar
  begin
    require "logstash-core/logstash-core.jar"
  rescue Exception => e
    raise("Error loading logstash-core/logstash-core.jar file, cause: #{e.message}")
  end
end
