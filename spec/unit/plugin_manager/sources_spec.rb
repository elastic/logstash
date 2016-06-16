# encoding: utf-8
require "spec_helper"
require 'webmock/rspec'
require "tmpdir"
require "pluginmanager/sources/http"
require "pluginmanager/sources/local"

describe LogStash::PluginManager::Sources::HTTP do

  subject   {  described_class.new(uri) }

  let(:uri) { "http://localhost:8080/pack.zip"}

  describe "#exist?" do

    it "should verify if a plugin exist in the repository" do
      stub_request(:head, uri).and_return(:status => 200)
      expect(subject.exist?).to eq(true)
    end

    it "should fail if a plugin does not exist in the repository" do
      stub_request(:head, uri).and_return(:status => 404)
      expect(subject.exist?).to eq(false)
    end

  end

  describe "#fetch" do

    before(:each) do
      File.delete("pack.zip") if File.exist?("pack.zip")
    end

   # after(:each) do
   #   File.delete("pack.zip") if File.exist?("pack.zip")
   # end

    it "should start the download process" do
      stub_request(:get, uri).and_return(:body => "foo", :status => 404)
      Dir.mktmpdir do |tmp_dir|
        filename, _ = subject.fetch(tmp_dir)
        expect(File).not_to exist(filename)
      end
    end

    it "should start the download process" do
      stub_request(:get, uri).and_return(:body => "foo", :status => 200)
      Dir.mktmpdir do |tmp_dir|
        filename, _ = subject.fetch(tmp_dir)
        expect(File).to exist(filename)
        expect(File.read(filename)).to eq("foo")
      end
    end
  end

  describe "#valid?" do

    let(:uri) { "http://localhost:8080/pack-#{LOGSTASH_VERSION}.zip"}

    it "validates resource existance" do
      stub_request(:head, uri).to_return(:status => 200)
      expect(subject.exist?).to be_truthy
    end

    context "when does not exist" do

      it "fails the validation" do
        stub_request(:head, uri).to_return(:status => 404)
        expect(subject.valid?).to be_falsey
      end
    end

    context "when does not have a valid format" do

      let(:uri) { "http://localhost:8080/pack-.gzip"}

      it "fails the validation" do
        stub_request(:head, uri).to_return(:status => 200)
        expect(subject.valid?).to be_falsey
      end
    end

  end
end

describe LogStash::PluginManager::Sources::Local do

  subject   {  described_class.new(uri) }

  let(:uri) { "/foo/bar-#{LOGSTASH_VERSION}.zip"}

  it "validates a file existance" do
    allow(::File).to receive(:exist?).with(uri).and_return(true)
    expect(subject.exist?).to be_truthy
  end

  context "#valid?" do

    before(:each) do
      allow(::File).to receive(:exist?).with(uri).and_return(true)
    end

    it "check for plugin validation" do
      expect(subject.valid?).to be_truthy
    end

    context "when having wrong version" do
      let(:uri) { "/foo/bar-1.0.zip"}

      it "fails the falidation" do
        expect(subject.valid?).to be_falsey
      end
    end

    context "when having wrong file ending" do
      let(:uri) { "/foo/bar-#{LOGSTASH_VERSION}.gzip"}

      it "fails the validation" do
        expect(subject.valid?).to be_falsey
      end
    end

    context "when no version is provided" do
      let(:uri) { "/foo/bar.zip"}

      it "fails the validation" do
        expect(subject.valid?).to be_falsey
      end
    end

  end

  describe "#fetch" do

    let(:destination) { "/destination/path" }

    it "copy a file from a given path to a destination" do
      destination_path = File.join(destination, "bar-#{LOGSTASH_VERSION}.zip")
      expect(::FileUtils).to receive(:cp).with(uri, destination_path).and_return(true)
      subject.fetch(destination)
    end

    it "uses LOSTASH_HOME if no destination is given" do
      destination_path = File.join(LogStash::Environment::LOGSTASH_HOME, "bar-#{LOGSTASH_VERSION}.zip")
      expect(::FileUtils).to receive(:cp).with(uri, destination_path).and_return(true)
      subject.fetch
    end
  end

end
