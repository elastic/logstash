require "rubygems"
$:.unshift File.dirname(__FILE__) + "/../../lib"
$:.unshift File.dirname(__FILE__) + "/../"

require "minitest/spec"
require "minitest/autorun" if $0 == __FILE__

describe "syntax check" do
  source = File.join(File.dirname(__FILE__), "..", "..", "lib", "logstash", "**", "*.rb")

  Dir.glob(source).each do |path|
    it "must load #{path} without syntax errors" do
      # We could use 'load' here but that implies a bunch more than just syntax
      # checking. Most especially it will fail if we try to use java libraries
      # not currently in the classpath.
      #begin
        #load path
      #rescue LoadError => e
        #flunk("Error loading #{path}: #{e.inspect}")
      #end
      assert(system("ruby", "-c", path), "Error parsing #{path}")
    end # syntax check a file
  end # find all ruby files
end # syntax check
