require "logstash/util/plugin_version"

describe LogStash::Util::PluginVersion do
  subject { LogStash::Util::PluginVersion }

  it 'contains the semver parts of a plugin version' do
    version = subject.new(1, 2, 3)

    expect(version.major).to eq(1)
    expect(version.minor).to eq(2)
    expect(version.patch).to eq(3)
  end
end
