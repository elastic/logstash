# encoding: utf-8
require "spec_helper"
require "logstash/plugin"
require "logstash/outputs/base"
require "logstash/codecs/base"
require "logstash/inputs/base"
require "logstash/filters/base"
require "support/shared_contexts"

describe LogStash::Plugin do
  context "reloadable" do
    context "by default" do
      subject do
        Class.new(LogStash::Plugin) do
        end
      end

      it "makes .reloadable? return true" do
        expect(subject.reloadable?).to be_truthy
      end

      it "makes #reloadable? return true" do
        expect(subject.new({}).reloadable?).to be_truthy
      end
    end

    context "user can overrides" do
      subject do
        Class.new(LogStash::Plugin) do
          def self.reloadable?
            false
          end
        end
      end

      it "makes .reloadable? return true" do
        expect(subject.reloadable?).to be_falsey
      end

      it "makes #reloadable? return true" do
        expect(subject.new({}).reloadable?).to be_falsey
      end
    end
  end

  context "#execution_context" do
    subject { Class.new(LogStash::Plugin).new({}) }
    include_context "execution_context"

    it "can be set and get" do
      expect(subject.execution_context).to be_nil
      subject.execution_context = execution_context
      expect(subject.execution_context).to eq(execution_context)
    end
  end

  it "should fail lookup on nonexistent type" do
    #expect_any_instance_of(Cabin::Channel).to receive(:debug).once
    expect { LogStash::Plugin.lookup("badbadtype", "badname") }.to raise_error(LogStash::PluginLoadingError)
  end

  it "should fail lookup on nonexistent name" do
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

      expect_any_instance_of(LogStash::Logging::Logger).not_to receive(:info)
      subject.validate({})
    end

    it 'warns the user if the plugin version is between 0.9.x and 1.0.0' do
      allow(Gem::Specification).to receive(:find_by_name)
        .with(plugin_name)
        .and_return(double(:version => Gem::Version.new('0.9.1')))

      expect_any_instance_of(LogStash::Logging::Logger).to receive(:info)
        .with(/Using version 0.9.x/)

      subject.validate({})
    end

    it 'warns the user if the plugin version is inferior to 0.9.x' do
      allow(Gem::Specification).to receive(:find_by_name)
        .with(plugin_name)
        .and_return(double(:version => Gem::Version.new('0.1.1')))

      expect_any_instance_of(LogStash::Logging::Logger).to receive(:info)
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

      expect_any_instance_of(LogStash::Logging::Logger).to receive(:info)
        .once
        .with(/Using version 0.1.x/)

      one_notice.validate({})
      one_notice.validate({})
    end

    it "doesn't raise an exception if no version is found" do
      expect { subject.validate({}) }.not_to raise_error
    end


    it 'logs a warning if the plugin use the milestone option' do
      expect_any_instance_of(LogStash::Logging::Logger).to receive(:debug)
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

  describe "#id" do
    plugin_types = [
      LogStash::Filters::Base,
      LogStash::Codecs::Base,
      LogStash::Outputs::Base,
      LogStash::Inputs::Base
    ]

    plugin_types.each do |plugin_type|
      let(:plugin) do
        Class.new(plugin_type) do
          config_name "simple_plugin"

          config :host, :validate => :string
          config :export, :validate => :boolean

          def register; end
        end
      end

      let(:config) do
        {
          "host" => "127.0.0.1",
          "export" => true
        }
      end

      subject { plugin.new(config) }

      context "plugin type is #{plugin_type}" do
        context "when there is not ID configured for the output" do
          it "it uses a UUID to identify this plugins" do
            expect(subject.id).not_to eq(nil)
          end

          it "will be different between instance of plugins" do
            expect(subject.id).not_to eq(plugin.new(config).id)
          end
        end

        context "When a user provide an ID for the plugin" do
          let(:id) { "ABC" }
          let(:config) { super.merge("id" => id) }

          it "uses the user provided ID" do
            expect(subject.id).to eq(id)
          end
        end
      end
    end
  end

  describe "#id" do
    let(:plugin) do
      Class.new(LogStash::Filters::Base,) do
        config_name "simple_plugin"
        config :host, :validate => :string

        def register; end
      end
    end

    let(:config) do
      {
        "host" => "127.0.0.1"
      }
    end

    context "when the id is provided" do
      let(:my_id) { "mysuper-plugin" }
      let(:config) { super.merge({ "id" => my_id })}
      subject { plugin.new(config) }

      it "return a human readable ID" do
        expect(subject.id).to eq(my_id)
      end
    end

    context "when the id is not provided provided" do
      subject { plugin.new(config) }

      it "return a human readable ID" do
        expect(subject.id).to match(/^simple_plugin_/)
      end
    end
  end


  context "When the plugin record a metric" do
    let(:config) { {} }

    [LogStash::Inputs::Base, LogStash::Filters::Base, LogStash::Outputs::Base].each do |base|
      let(:plugin) do
        Class.new(base) do
          #include LogStash::Util::Loggable
          config_name "testing"

          def register
            metric.gauge("power_level", 9000)
          end
        end
      end

      subject { plugin.new(config) }

      context "when no metric is set to the plugin" do
        context "when `enable_metric` is TRUE" do
          it "recording metric should not raise an exception" do
            expect { subject.register }.not_to raise_error
          end

          it "should use a `NullMetric`" do
            expect(subject.metric).to be_kind_of(LogStash::Instrument::NamespacedNullMetric)
          end
        end

        context "when `enable_metric` is FALSE" do
          let(:config) { { "enable_metric" => false } }

          it "recording metric should not raise an exception" do
            expect { subject.register }.not_to raise_error
          end

          it "should use a `NullMetric`" do
            expect(subject.metric).to be_kind_of(LogStash::Instrument::NamespacedNullMetric)
          end
        end
      end

      context "When a specific metric collector is configured" do
        context "when `enable_metric` is TRUE" do
          let(:metric) { LogStash::Instrument::Metric.new(LogStash::Instrument::Collector.new).namespace("dbz") }

          before :each do
            subject.metric = metric
          end

          it "recording metric should not raise an exception" do
            expect { subject.register }.not_to raise_error
          end

          it "should use the configured metric" do
            expect(subject.metric).to eq(metric)
          end
        end

        context "when `enable_metric` is FALSE" do
          let(:config) { { "enable_metric" => false } }

          it "recording metric should not raise an exception" do
            expect { subject.register }.not_to raise_error
          end

          it "should use a `NullMetric`" do
            expect(subject.metric).to be_kind_of(LogStash::Instrument::NamespacedNullMetric)
          end
        end
      end
    end
  end
end
