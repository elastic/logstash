# encoding: utf-8
require 'spec_helper'
require 'logstash/util/java_version'

describe "LogStash::Util::JavaVersion" do
  subject(:mod) { LogStash::Util::JavaVersion }

  it "should get the current java version if we're on Java" do
    if LogStash::Environment.jruby?
      expect(LogStash::Util::JavaVersion.version).to be_a(String)
    end
  end

  it "should mark a bad beta version as bad" do
    expect(mod.bad_java_version?("1.7.0_45-beta")).to be_truthy
  end

  it "should mark a bad standard version as bad" do
    expect(mod.bad_java_version?("1.6.0")).to be_truthy
  end

  it "should mark java 7 version as bad" do
    expect(mod.bad_java_version?("1.7.0_51")).to be_truthy
  end
  
  it "should mark java version 8 as good" do
    expect(mod.bad_java_version?("1.8.0")).to be_falsey
  end
  
  it "should mark a good standard java version as good" do
    expect(mod.bad_java_version?("1.8.0_65")).to be_falsey
  end
  
  it "should mark a good beta version as good" do
    expect(mod.bad_java_version?("1.8.0-beta")).to be_falsey
  end

  it "should not mark non-standard javas as bad (IBM JDK)" do
    expect(mod.bad_java_version?("pwi3270sr9fp10-20150708_01 (SR9 FP10)")).to be_falsey
  end

  describe "parsing java versions" do
    it "should return nil on a nil version" do
      expect(mod.parse_java_version(nil)).to be_nil
    end

    it "should return nil on non-hotspot javas" do
      # Not sure this is what is being returned, but it doesn't match the
      # regex, which is the point
      expect(mod.parse_java_version("JCL - 20140103_01 based on Oracle 7u51-b11

")).to be_nil
    end

    shared_examples("version parsing") do |desc, string, major, minor, patch, update, build|
      context("#{desc} with version #{string}") do
        subject(:parsed) { LogStash::Util::JavaVersion.parse_java_version(string) }

        it "should have the correct major version" do
          expect(parsed[:major]).to eql(major)
        end

        it "should have the correct minor version" do
          expect(parsed[:minor]).to eql(minor)
        end

        it "should have the correct patch version" do
          expect(parsed[:patch]).to eql(patch)
        end

        it "should have the correct update version" do
          expect(parsed[:update]).to eql(update)
        end

        it "should have the correct build string" do
          expect(parsed[:build]).to eql(build)
        end
      end
    end

    include_examples("version parsing", "a plain version", "1.3.0", 1, 3, 0, 0, nil)
    include_examples("version parsing", "an update", "1.4.0_03", 1, 4, 0, 3, nil)
    include_examples("version parsing", "a build", "1.4.0-beta", 1, 4, 0, 0,"beta")
    include_examples("version parsing", "an update+build", "1.4.0_03-beta", 1, 4, 0, 3, "beta")
  end

end
