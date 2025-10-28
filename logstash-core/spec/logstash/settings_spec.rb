# Licensed to Elasticsearch B.V. under one or more contributor
# license agreements. See the NOTICE file distributed with
# this work for additional information regarding copyright
# ownership. Elasticsearch B.V. licenses this file to you under
# the Apache License, Version 2.0 (the "License"); you may
# not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#  http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing,
# software distributed under the License is distributed on an
# "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
# KIND, either express or implied.  See the License for the
# specific language governing permissions and limitations
# under the License.

require "spec_helper"
require "logstash/util/substitution_variables"
require "logstash/settings"
require "fileutils"

describe LogStash::Settings do
  let(:numeric_setting_name) { "number" }
  let(:numeric_setting) { LogStash::Setting.new(numeric_setting_name, Numeric, 1) }

  describe "#register" do
    context "if setting has already been registered" do
      before :each do
        subject.register(numeric_setting)
      end
      it "should raise an exception" do
        expect { subject.register(numeric_setting) }.to raise_error
      end
      it "registered? should return true" do
        expect(subject.registered?(numeric_setting_name)).to be_truthy
      end
    end
    context "if setting hasn't been registered" do
      it "should not raise an exception" do
        expect { subject.register(numeric_setting) }.to_not raise_error
      end
      it "registered? should return false" do
        expect(subject.registered?(numeric_setting_name)).to be_falsey
      end
    end
  end

  describe "#get_setting" do
    context "if setting has been registered" do
      before :each do
        subject.register(numeric_setting)
      end
      it "should return the setting" do
        expect(subject.get_setting(numeric_setting_name)).to eq(numeric_setting)
      end
    end
    context "if setting hasn't been registered" do
      it "should raise an exception" do
        expect { subject.get_setting(numeric_setting_name) }.to raise_error
      end
    end
  end

  describe "#to_hash" do
    let(:java_deprecated_alias) { LogStash::Setting::BooleanSetting.new("java.actual", true).with_deprecated_alias("java.deprecated") }
    let(:ruby_deprecated_alias) { LogStash::Setting::PortRangeSetting.new("ruby.actual", 9600..9700).with_deprecated_alias("ruby.deprecated") }
    let(:non_deprecated) { LogStash::Setting::BooleanSetting.new("plain_setting", false) }

    before :each do
      subject.register(java_deprecated_alias)
      subject.register(ruby_deprecated_alias)
      subject.register(non_deprecated)
    end

    it "filter deprecated alias settings" do
      generated_settings_hash = subject.to_hash

      expect(generated_settings_hash).not_to have_key("java.deprecated")
      expect(generated_settings_hash).not_to have_key("ruby.deprecated")
      expect(generated_settings_hash).to have_key("java.actual")
      expect(generated_settings_hash).to have_key("ruby.actual")
      expect(generated_settings_hash).to have_key("plain_setting")
    end
  end

  describe "#get_subset" do
    let(:numeric_setting_1) { LogStash::Setting.new("num.1", Numeric, 1) }
    let(:numeric_setting_2) { LogStash::Setting.new("num.2", Numeric, 2) }
    let(:numeric_setting_3) { LogStash::Setting.new("num.3", Numeric, 3) }
    let(:string_setting_1) { LogStash::Setting.new("string.1", String, "hello") }
    before :each do
      subject.register(numeric_setting_1)
      subject.register(numeric_setting_2)
      subject.register(numeric_setting_3)
      subject.register(string_setting_1)
    end

    it "supports regex" do
      expect(subject.get_subset(/num/).get_setting("num.3")).to eq(numeric_setting_3)
      expect { subject.get_subset(/num/).get_setting("string.1") }.to raise_error
    end

    it "returns a copy of settings" do
      subset = subject.get_subset(/num/)
      subset.set("num.2", 1000)
      expect(subject.get("num.2")).to eq(2)
      expect(subset.get("num.2")).to eq(1000)
    end
  end

  describe "#validate_all" do
    subject { described_class.new }
    let(:numeric_setting_name) { "example" }
    let(:numeric_setting) { LogStash::Setting.new(numeric_setting_name, Numeric, 1, false) }

    before do
      subject.register(numeric_setting)
      subject.set_value(numeric_setting_name, value)
    end

    context "when any setting is invalid" do
      let(:value) { "some string" }

      it "should fail" do
        expect { subject.validate_all }.to raise_error
      end
    end

    context "when all settings are valid" do
      let(:value) { 123 }

      it "should succeed" do
        expect { subject.validate_all }.not_to raise_error
      end
    end
  end

  describe '#names' do
    subject(:settings) { described_class.new }
    before(:each) do
      settings.register(LogStash::Setting.new("one.two.three", String, "123", false))
      settings.register(LogStash::Setting.new("this.that", Integer, 123, false))
    end
    it 'returns a list of setting names' do
      expect(settings.names).to contain_exactly("one.two.three", "this.that")
    end
  end

  describe "post_process" do
    subject(:settings) { described_class.new }

    before do
      settings.on_post_process do
        settings.set("baz", "bot")
      end
      settings.register(LogStash::Setting::StringSetting.new("foo", "bar"))
      settings.register(LogStash::Setting::StringSetting.new("baz", "somedefault"))
      settings.post_process
    end

    it "should run the post process callbacks" do
      expect(settings.get("baz")).to eq("bot")
    end

    it "should preserve original settings" do
      expect(settings.get("foo")).to eq("bar")
    end

    context 'when a registered setting responds to `observe_post_process`' do
      let(:observe_post_process_setting) do
        LogStash::Setting::BooleanSetting.new("this.that", true).tap { |s| allow(s).to receive(:observe_post_process) }
      end
      subject(:settings) do
        described_class.new.tap { |s| s.register(observe_post_process_setting) }
      end
      it 'it sends `observe_post_process`' do
        expect(observe_post_process_setting).to have_received(:observe_post_process)
      end
    end
  end

  context "transient settings" do
    subject do
      settings = described_class.new
      settings.register(LogStash::Setting::StringSetting.new("exist", "bonsoir"))
      settings
    end

    let(:values) { { "do.not.exist.on.boot" => true, "exist" => "bonjour" } }
    let(:yaml_path) do
      p = Stud::Temporary.pathname
      FileUtils.mkdir_p(p)

      ::File.open(::File.join(p, "logstash.yml"), "w+") do |f|
        f.write(YAML.dump(values))
      end
      p
    end

    it "allow to read yml file that contains unknown settings" do
      expect { subject.from_yaml(yaml_path) }.not_to raise_error
    end

    context "when running #validate_all" do
      it "merge and validate all the registered setting" do
        subject.from_yaml(yaml_path)
        subject.register(LogStash::Setting::BooleanSetting.new("do.not.exist.on.boot", false))

        expect { subject.validate_all }.not_to raise_error
        expect(subject.get("do.not.exist.on.boot")).to be_truthy
      end

      it "raise an error when the settings doesn't exist" do
        subject.from_yaml(yaml_path)
        expect { subject.validate_all }.to raise_error(ArgumentError)
      end
    end
  end

  describe "#from_yaml" do
    before :each do
      LogStash::SETTINGS.set("keystore.file", File.join(File.dirname(__FILE__), "../../src/test/resources/logstash.keystore.with.default.pass"))
      LogStash::Util::SubstitutionVariables.send(:reset_secret_store)
    end

    after(:each) do
      LogStash::Util::SubstitutionVariables.send(:reset_secret_store)
    end

    context "placeholders in flat logstash.yml" do
      after do
        ENV.delete('SOME_LOGSTASH_SPEC_ENV_VAR')
        ENV.delete('some.logstash.spec.env.var')
        ENV.delete('a')
      end

      subject do
        settings = described_class.new
        settings.register(LogStash::Setting::StringSetting.new("interpolated_env", "missing"))
        settings.register(LogStash::Setting::StringSetting.new("with_dot_env", "missing"))
        settings.register(LogStash::Setting::StringSetting.new("interpolated_store", "missing"))
        settings
      end

      let(:values) {{
        "interpolated_env" => "${SOME_LOGSTASH_SPEC_ENV_VAR}",
        "with_dot_env" => "${some.logstash.spec.env.var}",
        "interpolated_store" => "${a}"
      }}
      let(:yaml_path) do
        p = Stud::Temporary.pathname
        FileUtils.mkdir_p(p)

        ::File.open(::File.join(p, "logstash.yml"), "w+") do |f|
          f.write(YAML.dump(values))
        end
        p
      end

      it "can interpolate into settings" do
        expect(subject.get('interpolated_env')).to eq("missing")
        expect(subject.get('with_dot_env')).to eq("missing")
        expect(subject.get('interpolated_store')).to eq("missing")
        ENV['SOME_LOGSTASH_SPEC_ENV_VAR'] = "correct_setting_env"
        ENV['some.logstash.spec.env.var'] = "correct_setting_for_dotted_env"
        ENV['a'] = "wrong_value" # the store should take precedence
        subject.from_yaml(yaml_path)
        expect(subject.get('interpolated_env')).to eq("correct_setting_env")
        expect(subject.get('with_dot_env')).to eq("correct_setting_for_dotted_env")
        expect(subject.get('interpolated_store')).to eq("A")
      end
    end
  end

  describe "#password_policy" do
    let(:password_policies) { {
      "mode": "ERROR",
      "length": { "minimum": "8"},
      "include": { "upper": "REQUIRED", "lower": "REQUIRED", "digit": "REQUIRED", "symbol": "REQUIRED" }
    } }

    context "when running PasswordValidator coerce" do
      it "raises an error when supplied value is not LogStash::Util::Password" do
        expect {
          LogStash::Setting::ValidatedPasswordSetting.new("test.validated.password", "testPassword", password_policies)
        }.to raise_error(IllegalArgumentException, a_string_including("Setting `test.validated.password` could not coerce LogStash::Util::Password value to password"))
      end

      it "fails on validation" do
        password = LogStash::Util::Password.new("Password!")
        expect {
          LogStash::Setting::ValidatedPasswordSetting.new("test.validated.password", password, password_policies)
        }.to raise_error(IllegalArgumentException, a_string_including("Password must contain at least one digit between 0 and 9."))
      end

      it "validates the password successfully" do
        password = LogStash::Util::Password.new("Password123!")
        expect(LogStash::Setting::ValidatedPasswordSetting.new("test.validated.password", password, password_policies)).to_not be_nil
      end
    end
  end

  context "placeholders in nested logstash.yml" do
    before :each do
      LogStash::SETTINGS.set("keystore.file", File.join(File.dirname(__FILE__), "../../src/test/resources/logstash.keystore.with.default.pass"))
      LogStash::Util::SubstitutionVariables.send(:reset_secret_store)
    end

    before do
      ENV['lsspecdomain_env'] = "domain1"
      ENV['lsspecdomain2_env'] = "domain2"
      ENV['a'] = "wrong_value" # the store should take precedence
    end

    after do
      ENV.delete('lsspecdomain_env')
      ENV.delete('lsspecdomain2_env')
      ENV.delete('a')
    end

    after(:each) do
      LogStash::Util::SubstitutionVariables.send(:reset_secret_store)
    end

    subject do
      settings = described_class.new
      settings.register(LogStash::Setting::ArrayCoercible.new("host", String, []))
      settings.register(LogStash::Setting::ArrayCoercible.new("modules", Hash, []))
      settings
    end

    let(:values) {{
      "host" => ["dev1.${lsspecdomain_env}", "dev2.${lsspecdomain_env}", "dev3.${a}"],
      "modules" => [
        {"name" => "${lsspecdomain_env}", "testing" => "${lsspecdomain_env}"},
        {"name" => "${lsspecdomain2_env}", "testing" => "${lsspecdomain2_env}"},
        {"name" => "${a}", "testing" => "${a}"},
        {"name" => "${b}", "testing" => "${b}"}
      ]
    }}
    let(:yaml_path) do
      p = Stud::Temporary.pathname
      FileUtils.mkdir_p(p)

      ::File.open(::File.join(p, "logstash.yml"), "w+") do |f|
        f.write(YAML.dump(values))
      end
      p
    end

    it "can interpolate environment into settings" do
      expect(subject.get('host')).to match_array([])
      expect(subject.get('modules')).to match_array([])
      subject.from_yaml(yaml_path)
      expect(subject.get('host')).to match_array(["dev1.domain1", "dev2.domain1", "dev3.A"])
      expect(subject.get('modules')).to match_array([
                                                      {"name" => "domain1", "testing" => "domain1"},
                                                      {"name" => "domain2", "testing" => "domain2"},
                                                      {"name" => "A", "testing" => "A"},
                                                      {"name" => "B", "testing" => "B"}
                                                    ])
    end
  end

  describe "deprecated pipeline override settings" do

    let(:subject) { described_class.new }
    before(:each) { subject.register(LogStash::Setting.new("pipeline.id", String, "main")) }

    context '#merge_pipeline_settings' do

      described_class::DEPRECATED_PIPELINE_OVERRIDE_SETTINGS.each do |setting|

        context "the setting (#{setting}) is set" do

          let(:deprecation_logger) { subject.deprecation_logger }
          let(:setting_value) { double('setting_value') }

          it "a warning is logged" do
            expect(deprecation_logger).to receive(:deprecated).with(
              a_string_matching("Config option \"#{setting}\", set for pipeline \"test\", is deprecated as a " +
                                  "pipeline override setting. Please only set it at the process level.")
            )
            subject.merge_pipeline_settings("pipeline.id" => "test", setting => setting_value)
          end

          it "it does not set (#{setting})" do
            subject.merge_pipeline_settings(setting => double('setting_value'))
            expect{ subject.get_setting(setting) }.to raise_error(ArgumentError)
          end

          context 'other settings are also set' do

            before(:each) do
              subject.register(LogStash::Setting::BooleanSetting.new("config.debug", false))
              subject.merge_pipeline_settings(setting => setting_value, "config.debug" => true)
            end

            it "it leaves other settings intact" do
              expect(subject.get_setting("config.debug").value).to be(true)
            end
          end
        end
      end
    end
  end
end
