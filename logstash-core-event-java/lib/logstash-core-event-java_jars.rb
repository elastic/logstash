# this is a generated file, to avoid over-writing it just delete this comment
begin
  require 'jar_dependencies'
rescue LoadError
  require 'com/fasterxml/jackson/core/jackson-databind/2.7.3/jackson-databind-2.7.3.jar'
  require 'org/apache/logging/log4j/log4j-api/2.6.2/log4j-api-2.6.2.jar'
  require 'com/fasterxml/jackson/core/jackson-annotations/2.7.0/jackson-annotations-2.7.0.jar'
  require 'com/fasterxml/jackson/module/jackson-module-afterburner/2.7.3/jackson-module-afterburner-2.7.3.jar'
  require 'com/fasterxml/jackson/dataformat/jackson-dataformat-cbor/2.7.3/jackson-dataformat-cbor-2.7.3.jar'
  require 'com/fasterxml/jackson/core/jackson-core/2.7.3/jackson-core-2.7.3.jar'
end

if defined? Jars
  require_jar( 'com.fasterxml.jackson.core', 'jackson-databind', '2.7.3' )
  require_jar( 'org.apache.logging.log4j', 'log4j-api', '2.6.2' )
  require_jar( 'com.fasterxml.jackson.core', 'jackson-annotations', '2.7.0' )
  require_jar( 'com.fasterxml.jackson.module', 'jackson-module-afterburner', '2.7.3' )
  require_jar( 'com.fasterxml.jackson.dataformat', 'jackson-dataformat-cbor', '2.7.3' )
  require_jar( 'com.fasterxml.jackson.core', 'jackson-core', '2.7.3' )
end
