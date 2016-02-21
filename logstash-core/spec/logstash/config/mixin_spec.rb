# encoding: utf-8
require "spec_helper"
require "logstash/config/mixin"

describe LogStash::Config::Mixin do
  context "when validating :bytes successfully" do
    subject do
      local_num_bytes = num_bytes # needs to be locally scoped :(
      Class.new(LogStash::Filters::Base) do
        include LogStash::Config::Mixin
        config_name "test"
        milestone 1
        config :size_bytes, :validate => :bytes
        config :size_default, :validate => :bytes, :default => "#{local_num_bytes}"
        config :size_upcase, :validate => :bytes
        config :size_downcase, :validate => :bytes
        config :size_space, :validate => :bytes
      end.new({
        "size_bytes" => "#{local_num_bytes}",
        "size_upcase" => "#{local_num_bytes}KiB".upcase,
        "size_downcase" => "#{local_num_bytes}KiB".downcase,
        "size_space" => "#{local_num_bytes} KiB"
      })
    end

    let!(:num_bytes) { rand(1000) }
    let!(:num_kbytes) { num_bytes * 1024 }

    it "should validate :bytes successfully with no units" do
      expect(subject.size_bytes).to eq(num_bytes)
    end

    it "should allow setting valid default" do
      expect(subject.size_default).to eq(num_bytes)
    end

    it "should be case-insensitive when parsing units" do
      expect(subject.size_upcase).to eq(num_kbytes)
      expect(subject.size_downcase).to eq(num_kbytes)
    end

    it "should accept one space between num_bytes and unit suffix" do
      expect(subject.size_space).to eq(num_kbytes)
    end
  end

  context "when raising configuration errors while validating" do
    it "should raise configuration error when provided with invalid units" do
      expect {
        Class.new(LogStash::Filters::Base) do
          include LogStash::Config::Mixin
          config_name "test"
          milestone 1
          config :size_file, :validate => :bytes
        end.new({"size_file" => "10 yolobytes"})
      }.to raise_error(LogStash::ConfigurationError)
    end

    it "should raise configuration error when provided with too many spaces" do
      expect {
        Class.new(LogStash::Filters::Base) do
          include LogStash::Config::Mixin
          config_name "test"
          milestone 1
          config :size_file, :validate => :bytes
        end.new({"size_file" => "10  kib"})
      }.to raise_error(LogStash::ConfigurationError)
    end
  end

  context "when validating :password" do
    let(:klass) do
      Class.new(LogStash::Filters::Base)  do
        config_name "fake"
        config :password, :validate => :password
      end
    end

    let(:secret) { "fancy pants" }
    subject { klass.new("password" => secret) }

    it "should be a Password object" do
      expect(subject.password).to(be_a(LogStash::Util::Password))
    end

    it "should make password values hidden" do
      expect(subject.password.to_s).to(be == "<password>")
      expect(subject.password.inspect).to(be == "<password>")
    end

    it "should show password values via #value" do
      expect(subject.password.value).to(be == secret)
    end

    it "should correctly copy password types" do
      clone = subject.class.new(subject.params)
      expect(clone.password.value).to(be == secret)
    end
  end

  describe "obsolete settings" do
    let(:plugin_class) do
      Class.new(LogStash::Inputs::Base) do
        include LogStash::Config::Mixin
        config_name "example"
        config :foo, :validate => :string, :obsolete => "This feature was removed."
      end
    end

    context "when using an obsolete setting" do
      it "should cause a configuration error" do
        expect {
          plugin_class.new("foo" => "hello")
        }.to raise_error(LogStash::ConfigurationError)
      end
    end

    context "when using an obsolete settings from the parent class" do
      it "should cause a configuration error" do
        expect {
          plugin_class.new("debug" => true)
        }.to raise_error(LogStash::ConfigurationError)
      end
    end

    context "when not using an obsolete setting" do
      it "should not cause a configuration error" do
        expect {
          plugin_class.new({})
        }.not_to raise_error
      end
    end
  end

  context "#params" do
    let(:plugin_class) do
      Class.new(LogStash::Filters::Base)  do
        config_name "fake"
        config :password, :validate => :password
        config :bad, :validate => :string, :default => "my default", :obsolete => "not here"
      end
    end

    subject { plugin_class.new({ "password" => "secret" }) }

    it "should not return the obsolete options" do
      expect(subject.params).not_to include("bad")
    end

    it "should include any other params" do
      expect(subject.params).to include("password")
    end
  end

  context "environment variable injection" do
    let(:plugin_class) do
      Class.new(LogStash::Filters::Base)  do
        config_name "one_plugin"
        config :oneString, :validate => :string
        config :oneBoolean, :validate => :boolean
        config :oneNumber, :validate => :number
        config :oneArray, :validate => :array
        config :oneHash, :validate => :hash
      end
    end

    ENV["MIXIN_SPEC_ENV_VAR"] = "123"

    subject {
      plugin_class.new({
        "oneString" => "${notExistingVar}",
        "oneBoolean" => "${notExistingVar:true}",
        "oneNumber" => "${MIXIN_SPEC_ENV_VAR}",
        "oneArray" => [ "first array value", "$MIXIN_SPEC_ENV_VAR" ],
        "oneHash" => { "key" => "$MIXIN_SPEC_ENV_VAR" }
      })
    }

    it "should have oneString param as empty string (env var not found)" do
      expect(subject.oneString).to(be == "")
    end

    it "should have oneNumber param with environment variable injected" do
      expect(subject.oneNumber).to(be == 123)
    end

    it "should have oneBoolean param with default value" do
      expect(subject.oneBoolean).to(be == true)
    end

    it "should have oneArray param with environment variable injected" do
      expect(subject.oneArray).to include("123")
    end

    it "should have oneHash param with environment variable injected" do
      expect(subject.oneHash["key"]).to(be == "123")
    end
  end

end
