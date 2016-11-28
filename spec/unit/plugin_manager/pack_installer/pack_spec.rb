# encoding: utf-8
require "pluginmanager/pack_installer/pack"
require "stud/temporary"

describe LogStash::PluginManager::PackInstaller::Pack do
  let(:extracted_plugin) { ::File.join(::File.dirname(__FILE__), "..", "..", "..", "support", "pack", "valid-pack") }

  subject { described_class.new(extracted_plugin) }

  context "when there is a plugin in the root of the pack" do
    it "a valid pack" do
      expect(subject.valid?).to be_truthy
    end

    it "returns the plugins" do
      expect(subject.plugins.size).to eq(1)
      expect(subject.plugins.collect(&:name)).to include("logstash-input-packtest")
    end

    it "returns the dependencies" do
      expect(subject.dependencies.size).to eq(1)
      expect(subject.dependencies.collect(&:name)).to include("logstash-input-packtestdep")
    end

    it "returns all the gems" do
      expect(subject.gems.size).to eq(2)
      expect(subject.gems.collect(&:name)).to include("logstash-input-packtest", "logstash-input-packtestdep")
    end
  end

  context "when there is no plugin in the root of the pack " do
    let(:extracted_plugin) { Stud::Temporary.pathname }

    it "a invalid pack" do
      expect(subject.valid?).to be_falsey
    end
  end
end

describe LogStash::PluginManager::PackInstaller::Pack::GemInformation do
  subject { described_class.new(gem) }

  shared_examples "gem information" do
    it "returns the version" do
      expect(subject.version).to eq("3.1.8")
    end

    it "returns the name" do
      expect(subject.name).to eq("logstash-input-foobar")
    end

    it "returns the path of the gem" do
      expect(subject.file).to eq(gem)
    end
  end

  context "with a universal gem" do
    let(:gem) { "/tmp/logstash-input-foobar-3.1.8.gem" }

    include_examples "gem information"

    it "returns nil for the platform" do
      expect(subject.platform).to be_nil
    end
  end

  context "with a java gem" do
    let(:gem) { "/tmp/logstash-input-foobar-3.1.8-java.gem" }

    include_examples "gem information"

    it "returns nil for the platform" do
      expect(subject.platform).to eq("java")
    end
  end

  context "when its a plugin to be added to the gemfile" do
    let(:gem) { "/tmp/logstash-input-foobar-3.1.8-java.gem" }

    it "#dependency? return false" do
      expect(subject.dependency?).to be_falsey
    end

    it "#plugin? return true" do
      expect(subject.plugin?).to be_truthy
    end
  end

  context "when its a dependency of a plugin" do
    let(:gem) { "/tmp/dependencies/logstash-input-foobar-3.1.8-java.gem" }

    it "#dependency? return true" do
      expect(subject.dependency?).to be_truthy
    end

    it "#plugin? return false" do
      expect(subject.plugin?).to be_falsey
    end
  end
end
