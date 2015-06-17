require 'spec_helper'
require 'logstash/util/java_version'

describe "LogStash::Util::JavaVersion" do
  subject(:mod) { LogStash::Util::JavaVersion }

  it "should get the current java version if we're on Java" do
    if LogStash::Environment.jruby?
      expect(LogStash::Util::JavaVersion.version).to be_a(String)
    end
  end

  it "should mark a bad java version as bad" do
    expect(mod.bad_java_version?("1.7.0_45-beta")).to be_truthy
    expect(mod.bad_java_version?("1.6.0")).to be_truthy
  end

  it "should mark a good java version as good" do
    expect(mod.bad_java_version?("1.7.0_51")).to be_falsey
    expect(mod.bad_java_version?("1.8.0-beta")).to be_falsey
  end

  describe "parsing java versions" do
    it "should return nil on a nil version" do
      expect(mod.parse_java_version(nil)).to be_nil
    end

    it "should parse a plain version" do
      parsed = mod.parse_java_version("1.3.0")
      expect(parsed[:major]).to eql(1)
      expect(parsed[:minor]).to eql(3)
      expect(parsed[:patch]).to eql(0)
      expect(parsed[:update]).to eql(0)
      expect(parsed[:build]).to be_nil
    end

    it "should parse an update" do
      parsed = mod.parse_java_version("1.4.0_03")
      expect(parsed[:major]).to eql(1)
      expect(parsed[:minor]).to eql(4)
      expect(parsed[:patch]).to eql(0)
      expect(parsed[:update]).to eql(3)
      expect(parsed[:build]).to be_nil
    end

    it "should parse a version with just a build" do
      parsed = mod.parse_java_version("1.4.0-beta")
      expect(parsed[:major]).to eql(1)
      expect(parsed[:minor]).to eql(4)
      expect(parsed[:patch]).to eql(0)
      expect(parsed[:update]).to eql(0)
      expect(parsed[:build]).to eql("beta")
    end

    it "should parse a version with an update and a build" do
      parsed = mod.parse_java_version("1.4.0_03-beta")
      expect(parsed[:major]).to eql(1)
      expect(parsed[:minor]).to eql(4)
      expect(parsed[:patch]).to eql(0)
      expect(parsed[:update]).to eql(3)
      expect(parsed[:build]).to eql("beta")
    end
  end

end