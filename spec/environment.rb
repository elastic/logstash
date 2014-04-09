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

  describe "assess_jruby!" do

    it "should not raise when jruby" do
      expect(LogStash::Environment).to receive(:jruby?).twice.and_return(true)
      expect{LogStash::Environment.assess_jruby!}.to_not raise_error
      expect{LogStash::Environment.assess_jruby!{StandardError.new}}.to_not raise_error
    end

    it "should raise default exception" do
      expect(LogStash::Environment).to receive(:jruby?).once.and_return(false)
      expect{LogStash::Environment.assess_jruby!}.to raise_error(LogStash::EnvironmentError)
    end

    it "should yield to block and raise returned exception" do
      expect(LogStash::Environment).to receive(:jruby?).once.and_return(false)
      expect{LogStash::Environment.assess_jruby!{StandardError.new}}.to raise_error(StandardError)
    end

    it "should yield to block and raise default exception if exception not returned" do
      expect(LogStash::Environment).to receive(:jruby?).once.and_return(false)
      expect{LogStash::Environment.assess_jruby!{nil}}.to raise_error(LogStash::EnvironmentError)
    end
  end
end
