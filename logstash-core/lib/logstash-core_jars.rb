# this is a generated file, to avoid over-writing it just delete this comment
begin
  require 'jar_dependencies'
rescue LoadError
  require 'org/apache/logging/log4j/log4j-core/2.6.2/log4j-core-2.6.2.jar'
  require 'com/fasterxml/jackson/core/jackson-databind/2.9.1/jackson-databind-2.9.1.jar'
  require 'org/apache/logging/log4j/log4j-api/2.6.2/log4j-api-2.6.2.jar'
  require 'org/slf4j/slf4j-api/1.7.21/slf4j-api-1.7.21.jar'
  require 'com/fasterxml/jackson/core/jackson-annotations/2.9.1/jackson-annotations-2.9.1.jar'
  require 'org/apache/logging/log4j/log4j-slf4j-impl/2.6.2/log4j-slf4j-impl-2.6.2.jar'
  require 'com/fasterxml/jackson/module/jackson-module-afterburner/2.9.1/jackson-module-afterburner-2.9.1.jar'
  require 'com/fasterxml/jackson/dataformat/jackson-dataformat-cbor/2.9.1/jackson-dataformat-cbor-2.9.1.jar'
  require 'com/fasterxml/jackson/core/jackson-core/2.9.1/jackson-core-2.9.1.jar'
end

if defined? Jars
  require_jar 'org.apache.logging.log4j', 'log4j-core', '2.6.2'
  require_jar 'com.fasterxml.jackson.core', 'jackson-databind', '2.9.1'
  require_jar 'org.apache.logging.log4j', 'log4j-api', '2.6.2'
  require_jar 'org.slf4j', 'slf4j-api', '1.7.21'
  require_jar 'com.fasterxml.jackson.core', 'jackson-annotations', '2.9.1'
  require_jar 'org.apache.logging.log4j', 'log4j-slf4j-impl', '2.6.2'
  require_jar 'com.fasterxml.jackson.module', 'jackson-module-afterburner', '2.9.1'
  require_jar 'com.fasterxml.jackson.dataformat', 'jackson-dataformat-cbor', '2.9.1'
  require_jar 'com.fasterxml.jackson.core', 'jackson-core', '2.9.1'
end
