# Copyright Elasticsearch B.V. and/or licensed to Elasticsearch B.V. under one
# or more contributor license agreements. Licensed under the Elastic License;
# you may not use this file except in compliance with the Elastic License.

require "spec_helper"
require "logstash/environment"
require "logstash/settings"
require "security/extension"

describe LogStash::Security::Extension do
  let(:extension) { described_class.new }

  describe "#register_hook" do
    subject(:hooks) { LogStash::Plugins::HooksRegistry.new }

    before { extension.register_hooks(hooks) }

    it "register hooks on `LogStash::Runner`" do
      expect(hooks).to have_registered_hook(LogStash::Runner, LogStash::Security::Hooks)
    end
  end

  describe "#additionals_settings" do
    subject(:settings) { LogStash::Runner::SYSTEM_SETTINGS.clone }

    before { extension.additionals_settings(settings) }

    define_settings(
      "xpack.security.fips_mode.enabled" => [LogStash::Setting::BooleanSetting, false],
      "xpack.security.fips_mode.required_providers" => [LogStash::Setting::StringArray, []]
    )
  end
end
