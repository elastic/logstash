require "logstash/environment"

describe LogStash::Environment do

  describe "load_elasticsearch_jars!" do

    it "should load elasticsarch jars" do
      expect{LogStash::Environment.load_elasticsearch_jars!}.to_not raise_error
    end

    it "should raise when cannot find elasticsarch jars" do
      stub_const("LogStash::Environment::JAR_DIR", "/some/invalid/path")
      expect{LogStash::Environment.load_elasticsearch_jars!}.to raise_error(LogStash::EnvironmentError)
    end
  end

  describe "log4j_loaded?" do

    it "should find log4j" do
      expect{LogStash::Environment.load_elasticsearch_jars!}.to_not raise_error
      expect(LogStash::Environment.log4j_loaded?).to be_true
    end

    it "should not find log4j" do
      # temporarily turn off verbosity to avoid warning: already initialized constant Java
      saved_verbose = $VERBOSE
      $VERBOSE = nil

      # temporarily reset Java module
      saved_java = Java rescue nil
      Java = Module.new if saved_java

      expect(LogStash::Environment.log4j_loaded?).to be_false

      # restore Java and verbosity
      Java = saved_java
      $VERBOSE = saved_verbose
    end
  end
end
