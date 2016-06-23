# encoding: utf-8
require "logstash/plugin"
require "logstash/inputs/base"
require "logstash/filters/base"
require "logstash/outputs/base"
require "spec_helper"

describe LogStash::Plugin do
  it "should fail lookup on inexisting type" do
    #expect_any_instance_of(Cabin::Channel).to receive(:debug).once
    expect { LogStash::Plugin.lookup("badbadtype", "badname") }.to raise_error(LogStash::PluginLoadingError)
  end

  it "should fail lookup on inexisting name" do
    #expect_any_instance_of(Cabin::Channel).to receive(:debug).once
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

  describe "#inspect" do
    class LogStash::Filters::MyTestFilter < LogStash::Filters::Base
      config_name "param1"
      config :num, :validate => :number, :default => 20
      config :str, :validate => :string, :default => "test"
    end
    subject { LogStash::Filters::MyTestFilter.new("num" => 1, "str" => "hello") }

    it "should print the class of the filter" do
      expect(subject.inspect).to match(/^<LogStash::Filters::MyTestFilter/)
    end
    it "should list config options and values" do
      expect(subject.inspect).to match(/num=>1, str=>"hello"/)
    end
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

      expect_any_instance_of(Cabin::Channel).not_to receive(:info)
      subject.validate({})
    end

    it 'warns the user if the plugin version is between 0.9.x and 1.0.0' do
      allow(Gem::Specification).to receive(:find_by_name)
        .with(plugin_name)
        .and_return(double(:version => Gem::Version.new('0.9.1')))

      expect_any_instance_of(Cabin::Channel).to receive(:info)
        .with(/Using version 0.9.x/)

      subject.validate({})
    end

    it 'warns the user if the plugin version is inferior to 0.9.x' do
      allow(Gem::Specification).to receive(:find_by_name)
        .with(plugin_name)
        .and_return(double(:version => Gem::Version.new('0.1.1')))

      expect_any_instance_of(Cabin::Channel).to receive(:info)
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

      expect_any_instance_of(Cabin::Channel).to receive(:info)
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


    it 'logs a warning if the plugin use the milestone option' do
      expect_any_instance_of(Cabin::Channel).to receive(:debug)
        .with(/stromae plugin is using the 'milestone' method/)

      class LogStash::Filters::Stromae < LogStash::Filters::Base
        config_name "stromae"
        milestone 2
      end
    end
  end

  describe "subclass initialize" do
    let(:args) { Hash.new }

    [
      StromaeCodec = Class.new(LogStash::Codecs::Base) do
        config_name "stromae"
        config :foo_tag, :validate => :string, :default => "bar"
      end,
      StromaeFilter = Class.new(LogStash::Filters::Base) do
        config_name "stromae"
        config :foo_tag, :validate => :string, :default => "bar"
      end,
      StromaeInput = Class.new(LogStash::Inputs::Base) do
        config_name "stromae"
        config :foo_tag, :validate => :string, :default => "bar"
      end,
      StromaeOutput = Class.new(LogStash::Outputs::Base) do
        config_name "stromae"
        config :foo_tag, :validate => :string, :default => "bar"
      end
    ].each do |klass|

      it "subclass #{klass.name} does not modify params" do
        klass.new(args)
        expect(args).to be_empty
      end
    end

    context "codec initialization" do

      class LogStash::Codecs::Noop < LogStash::Codecs::Base
        config_name "noop"

        config :format, :validate => :string
        def register; end
      end

      it "should only register once" do
        args   = { "codec" => LogStash::Codecs::Noop.new("format" => ".") }
        expect_any_instance_of(LogStash::Codecs::Noop).to receive(:register).once
        LogStash::Plugin.new(args)
      end

    end
  end
  context "Collecting Metric in the plugin" do
    [LogStash::Inputs::Base, LogStash::Filters::Base, LogStash::Outputs::Base].each do |type|
      let(:plugin) do
        Class.new(type) do
          config_name "goku"

          def register
            metric.gauge("power-level", 9000)
          end
        end
      end

      subject { plugin.new }

      it "should not raise an exception when recoding a metric" do
        expect { subject.register }.not_to raise_error
      end

      it "should use a `NullMetric`" do
        expect(subject.metric).to be_kind_of(LogStash::Instrument::NullMetric)
      end
    end
  end
end
