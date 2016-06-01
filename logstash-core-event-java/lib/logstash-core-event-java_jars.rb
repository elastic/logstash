# this is a generated file, to avoid over-writing it just delete this comment
begin
  require 'jar_dependencies'
rescue LoadError
  require 'com/fasterxml/jackson/core/jackson-core/2.7.1/jackson-core-2.7.1.jar'
  require 'com/fasterxml/jackson/core/jackson-annotations/2.7.0/jackson-annotations-2.7.0.jar'
  require 'com/fasterxml/jackson/core/jackson-databind/2.7.1-1/jackson-databind-2.7.1-1.jar'
end

if defined? Jars
  require_jar( 'com.fasterxml.jackson.core', 'jackson-core', '2.7.1' )
  require_jar( 'com.fasterxml.jackson.core', 'jackson-annotations', '2.7.0' )
  require_jar( 'com.fasterxml.jackson.core', 'jackson-databind', '2.7.1-1' )
end
