# encoding: utf-8
require "pluginmanager/gem_installer"
require "pluginmanager/ui"
require "stud/temporary"
require "rubygems/specification"
require "fileutils"
require "ostruct"

describe LogStash::PluginManager::GemInstaller do
  let(:plugin_name) { "logstash-input-packtest-0.0.1" }
  let(:simple_gem) { ::File.join(::File.dirname(__FILE__), "..", "..", "support", "pack", "valid-pack", "logstash", "valid-pack", "#{plugin_name}.gem") }

  subject { described_class }
  let(:temporary_gem_home) { p = Stud::Temporary.pathname; FileUtils.mkdir_p(p); p }

  it "install the specifications in the spec dir" do
    subject.install(simple_gem, false, temporary_gem_home)
    spec_file = ::File.join(temporary_gem_home, "specifications", "#{plugin_name}.gemspec")
    expect(::File.exist?(spec_file)).to be_truthy
    expect(::File.size(spec_file)).to be > 0
  end

  it "install the gem in the gems dir" do
    subject.install(simple_gem, false, temporary_gem_home)
    gem_dir = ::File.join(temporary_gem_home, "gems", plugin_name)
    expect(Dir.exist?(gem_dir)).to be_truthy
  end

  context "post_install_message" do
    let(:message) { "Hello from the friendly pack" }

    context "when present" do
      before do
        allow_any_instance_of(::Gem::Specification).to receive(:post_install_message).and_return(message)
      end

      context "when we want the message" do
        it "display the message" do
          expect(LogStash::PluginManager.ui).to receive(:info).with(message)
          subject.install(simple_gem, true, temporary_gem_home)
        end
      end

      context "when we dont want the message" do
        it "doesn't display the message" do
          expect(LogStash::PluginManager.ui).not_to receive(:info).with(message)
          subject.install(simple_gem, false, temporary_gem_home)
        end
      end
    end

    context "when not present" do
      context "when we want the message" do
        it "doesn't display the message" do
          expect(LogStash::PluginManager.ui).not_to receive(:info).with(message)
          subject.install(simple_gem, true, temporary_gem_home)
        end
      end
    end
  end
end
