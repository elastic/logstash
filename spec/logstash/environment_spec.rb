# encoding: utf-8
require "spec_helper"
require "logstash/environment"

describe LogStash::Environment do

  context "when loading jars dependencies" do

    let(:default_jars_location)    { File.join("vendor", "jar-dependencies") }
    let(:default_runtime_location) { File.join(default_jars_location,"runtime-jars","*.jar") }
    let(:default_test_location)    { File.join(default_jars_location,"test-jars","*.jar") }

    it "raises an exception if jruby is not available" do
      expect(subject).to receive(:jruby?).and_return(false)
      expect { subject.load_runtime_jars! }.to raise_error
    end

    it "find runtime jars in the default location" do
      expect(subject).to receive(:find_jars).with(default_runtime_location).and_return([])
      subject.load_runtime_jars!
    end

    it "find test jars in the default location" do
      expect(subject).to receive(:find_jars).with(default_test_location).and_return([])
      subject.load_test_jars!
    end

    context "when loading a jar file" do

      let(:dummy_jar_file) { File.join(default_jars_location,"runtime-jars","elasticsearch.jar") }

      it "requires the jar files if there are jars to load" do
        expect(subject).to receive(:find_jars).with(default_runtime_location).and_return([dummy_jar_file])
        expect(subject).to receive(:require).with(dummy_jar_file)
        subject.load_runtime_jars!
      end

      it "raises an exception if there are no jars to load" do
        allow(Dir).to receive(:glob).and_return([])
        expect { subject.load_runtime_jars! }.to raise_error
      end
    end
  end

  context "add_plugin_path" do
    let(:path) { "/some/path" }

    before(:each) { expect($LOAD_PATH).to_not include(path) }
    after(:each) { $LOAD_PATH.delete(path) }

    it "should add the path to $LOAD_PATH" do
      expect{subject.add_plugin_path(path)}.to change{$LOAD_PATH.size}.by(1)
      expect($LOAD_PATH).to include(path)
    end
  end


  describe "OS detection" do
    windows_host_os = %w(bccwin cygwin mingw mswin wince)
    linux_host_os = %w(linux)

    context "windows" do
      windows_host_os.each do |host|
        it "#{host} returns true" do
          expect(RbConfig::CONFIG).to receive(:[]).with("host_os").and_return(host)
          expect(LogStash::Environment.windows?).to be_truthy
        end
      end

      linux_host_os.each do |host|
        it "#{host} returns false" do
          expect(RbConfig::CONFIG).to receive(:[]).with("host_os").and_return(host)
          expect(LogStash::Environment.windows?).to be_falsey
        end
      end
    end

    context "Linux" do
      windows_host_os.each do |host|
        it "#{host} returns true" do
          expect(RbConfig::CONFIG).to receive(:[]).with("host_os").and_return(host)
          expect(LogStash::Environment.linux?).to be_falsey
        end
      end

      linux_host_os.each do |host|
        it "#{host} returns false" do
          expect(RbConfig::CONFIG).to receive(:[]).with("host_os").and_return(host)
          expect(LogStash::Environment.linux?).to be_truthy
        end
      end
    end
  end
end
