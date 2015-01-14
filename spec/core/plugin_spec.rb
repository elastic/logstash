require "logstash/namespace"
require "logstash/plugin"
require "logstash/filters/base"

describe LogStash::Plugin do
  it "should fail lookup on inexisting type" do
    expect_any_instance_of(Cabin::Channel).to receive(:debug).once
    expect { LogStash::Plugin.lookup("badbadtype", "badname") }.to raise_error(LogStash::PluginLoadingError)
  end

  it "should fail lookup on inexisting name" do
    expect_any_instance_of(Cabin::Channel).to receive(:debug).once
    expect { LogStash::Plugin.lookup("filter", "badname") }.to raise_error(LogStash::PluginLoadingError)
  end

  it "should fail on bad plugin class" do
    LogStash::Filters::BadSuperClass = Class.new
    expect { LogStash::Plugin.lookup("filter", "bad_super_class") }.to raise_error(LogStash::PluginLoadingError)
  end

  it "should fail on missing config_name method" do
    LogStash::Filters::MissingConfigName = Class.new(LogStash::Filters::Base)
    expect { LogStash::Plugin.lookup("filter", "missing_config_name") }.to raise_error(LogStash::PluginLoadingError)
  end

  it "should lookup an already defined plugin class" do
    class LogStash::Filters::LadyGaga < LogStash::Filters::Base
      config_name "lady_gaga"
    end
    expect(LogStash::Plugin.lookup("filter", "lady_gaga")).to eq(LogStash::Filters::LadyGaga)
  end

  context "when validating the plugin version" do
    let(:plugin_name) { 'logstash-filter-stromae' }
    subject do
      Class.new(LogStash::Filters::Base) do
        config_name 'stromae'
      end
    end

    it "doesn't warn the user if the version is superior or equal to 1.0.0" do
      allow(Gem::Specification).to receive(:find_by_name)
        .with(plugin_name)
        .and_return(double(:version => Gem::Version.new('1.0.0')))

      expect_any_instance_of(Cabin::Channel).not_to receive(:warn)
      subject.validate({})
    end

    it 'warns the user if the plugin version is between 0.9.x and 1.0.0' do
      allow(Gem::Specification).to receive(:find_by_name)
        .with(plugin_name)
        .and_return(double(:version => Gem::Version.new('0.9.1')))

      expect_any_instance_of(Cabin::Channel).to receive(:warn)
        .with(/Using version 0.9.x/)

      subject.validate({})
    end

    it 'warns the user if the plugin version is inferior to 0.9.x' do
      allow(Gem::Specification).to receive(:find_by_name)
        .with(plugin_name)
        .and_return(double(:version => Gem::Version.new('0.1.1')))

      expect_any_instance_of(Cabin::Channel).to receive(:warn)
        .with(/Using version 0.1.x/)
      subject.validate({})
    end

    it "doesnt show the version notice more than once" do
      one_notice = Class.new(LogStash::Filters::Base) do
        config_name "stromae"
      end

      allow(Gem::Specification).to receive(:find_by_name)
        .with(plugin_name)
        .and_return(double(:version => Gem::Version.new('0.1.1')))

      expect_any_instance_of(Cabin::Channel).to receive(:warn)
        .once
        .with(/Using version 0.1.x/)

      one_notice.validate({})
      one_notice.validate({})
    end

    it "warns the user if we can't find a defined version" do
      expect_any_instance_of(Cabin::Channel).to receive(:warn)
        .once
        .with(/plugin doesn't have a version/)

      subject.validate({})
    end
    

    it 'logs an error if the plugin use the milestone option' do
      expect_any_instance_of(Cabin::Channel).to receive(:error)
        .with(/stromae plugin is using the 'milestone' method/)

      class LogStash::Filters::Stromae < LogStash::Filters::Base
        config_name "stromae"
        milestone 2
      end
    end
  end
end
