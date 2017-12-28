# this is a generated file, to avoid over-writing it just delete this comment
begin
  require 'jar_dependencies'
rescue LoadError
  require 'org/slf4j/slf4j-api/1.7.25/slf4j-api-1.7.25.jar'
  require 'com/fasterxml/jackson/core/jackson-databind/2.9.1/jackson-databind-2.9.1.jar'
  require 'com/fasterxml/jackson/core/jackson-annotations/2.9.1/jackson-annotations-2.9.1.jar'
  require 'org/apache/logging/log4j/log4j-api/2.9.1/log4j-api-2.9.1.jar'
  require 'org/apache/logging/log4j/log4j-core/2.9.1/log4j-core-2.9.1.jar'
  require 'com/fasterxml/jackson/dataformat/jackson-dataformat-cbor/2.9.1/jackson-dataformat-cbor-2.9.1.jar'
  require 'org/codehaus/janino/commons-compiler/3.0.7/commons-compiler-3.0.7.jar'
  require 'org/apache/logging/log4j/log4j-slf4j-impl/2.9.1/log4j-slf4j-impl-2.9.1.jar'
  require 'com/fasterxml/jackson/core/jackson-core/2.9.1/jackson-core-2.9.1.jar'
  require 'org/codehaus/janino/janino/3.0.7/janino-3.0.7.jar'
end

if defined? Jars
  require_jar( 'org.slf4j', 'slf4j-api', '1.7.25' )
  require_jar( 'com.fasterxml.jackson.core', 'jackson-databind', '2.9.1' )
  require_jar( 'com.fasterxml.jackson.core', 'jackson-annotations', '2.9.1' )
  require_jar( 'org.apache.logging.log4j', 'log4j-api', '2.9.1' )
  require_jar( 'org.apache.logging.log4j', 'log4j-core', '2.9.1' )
  require_jar( 'com.fasterxml.jackson.dataformat', 'jackson-dataformat-cbor', '2.9.1' )
  require_jar( 'org.codehaus.janino', 'commons-compiler', '3.0.7' )
  require_jar( 'org.apache.logging.log4j', 'log4j-slf4j-impl', '2.9.1' )
  require_jar( 'com.fasterxml.jackson.core', 'jackson-core', '2.9.1' )
  require_jar( 'org.codehaus.janino', 'janino', '3.0.7' )
end
