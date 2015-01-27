require "spec_helper"
require "logstash/util/plugin_version"
require "logstash/errors"

describe LogStash::Util::PluginVersion do
  subject { LogStash::Util::PluginVersion }

  context "#find_version!" do
    it 'raises an PluginNoVersionError if we cant find the plugin in the gem path' do
      dummy_name ='this-character-doesnt-exist-in-the-marvel-universe'
      expect { subject.find_version!(dummy_name) }.to raise_error(LogStash::PluginNoVersionError)
    end

    it 'returns the version of the gem' do
      expect { subject.find_version!('bundler') }.not_to raise_error
    end
  end

  context "#new" do
    it 'accepts a Gem::Version instance as argument' do
      version = Gem::Version.new('1.0.1')
      expect(subject.new(version).to_s).to eq(version.to_s)
    end

    it 'accepts an array for defining the version' do
      version = subject.new(1, 0, 2)
      expect(version.to_s).to eq('1.0.2')
    end
  end

  context "When comparing instances" do
    it 'allow to check if the version is newer or older' do
      old_version = subject.new(0, 1, 0)
      new_version = subject.new(1, 0, 1)

      expect(old_version).to be < new_version
      expect(old_version).to be <= new_version
      expect(new_version).to be > old_version
      expect(new_version).to be >= old_version
    end

    it 'return true if the version are equal' do
      version1 = subject.new(0, 1, 0)
      version2 = subject.new(0, 1, 0)

      expect(version1).to eq(version2)
    end
  end
end
