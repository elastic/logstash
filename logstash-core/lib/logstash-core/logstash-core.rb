# encoding: utf-8

require "java"

module LogStash
end

require "logstash-core_jars"

# local dev setup
alt_classdir = File.expand_path("../../../out/production/classes", __FILE__) #IntelliJ's gradle output as of 2017.02 https://youtrack.jetbrains.com/issue/IDEA-175172
if File.directory?(alt_classdir)
  classes_dir = alt_classdir
  resources_dir = File.expand_path("../../../out/production/resources", __FILE__)
else
  classes_dir = File.expand_path("../../../build/classes/java/main", __FILE__)
  resources_dir = File.expand_path("../../../build/resources/main", __FILE__)
end



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

# Load Logstash's Java-defined RubyClasses by classloading RubyUtil which sets them up in its
# static constructor
java_import org.logstash.RubyUtil
