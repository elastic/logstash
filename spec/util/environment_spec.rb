require "spec_helper"
require "logstash/environment"

describe LogStash::Environment do

  describe "load_elasticsearch_jars!" do

    it "should load elasticsarch jars" do
      expect{LogStash::Environment.load_elasticsearch_jars!}.to_not raise_error
    end

    it "should raise when cannot find elasticsearch jars" do
      stub_const("LogStash::Environment::ELASTICSEARCH_DIR", "/some/invalid/path")
      expect{LogStash::Environment.load_elasticsearch_jars!}.to raise_error(LogStash::EnvironmentError)
    end
  end

  describe "load_jars!" do
    it "should load custom jars" do
      expect{LogStash::Environment.load_jars!(LogStash::Environment::LOGSTASH_HOME,"vendor","jruby","lib","jruby.jar")}.to_not raise_error
    end

    it "should raise when cannot find jars" do
      expect{LogStash::Environment.load_jars!(LogStash::Environment::LOGSTASH_HOME,"non-exisiting","jar.jar")}.to raise_error(LogStash::EnvironmentError)
    end
  end
end
