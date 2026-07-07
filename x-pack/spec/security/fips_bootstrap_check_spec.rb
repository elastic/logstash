# Copyright Elasticsearch B.V. and/or licensed to Elasticsearch B.V. under one
# or more contributor license agreements. Licensed under the Elastic License;
# you may not use this file except in compliance with the Elastic License.

require "spec_helper"
require "logstash/environment"
require "logstash/settings"
require "security/extension"

describe LogStash::Security::FipsBootstrapCheck do
  subject(:check) { described_class.check(settings) }

  let(:settings) { LogStash::Runner::SYSTEM_SETTINGS.clone }

  before do
    LogStash::Security::Extension.new.additionals_settings(settings)
  end

  context "when FIPS mode is disabled" do
    it "does not validate providers" do
      expect { check }.not_to raise_error
    end
  end

  context "when FIPS mode is enabled without required providers" do
    before do
      settings.set("xpack.security.fips_mode.enabled", true)
    end

    it "does not validate providers" do
      expect { check }.not_to raise_error
    end
  end

  context "when FIPS mode requires an installed provider" do
    before do
      settings.set("xpack.security.fips_mode.enabled", true)
      settings.set("xpack.security.fips_mode.required_providers", ["SUN"])
    end

    it "passes when the provider is available" do
      expect { check }.not_to raise_error
    end
  end

  context "when FIPS mode requires a missing provider" do
    before do
      settings.set("xpack.security.fips_mode.enabled", true)
      settings.set("xpack.security.fips_mode.required_providers", ["LOGSTASH_MISSING_FIPS_PROVIDER", "LOGSTASH_MISSING_JSSE_PROVIDER:2*"])
    end

    it "raises a bootstrap check error with missing providers" do
      expect { check }.to raise_error(LogStash::BootstrapCheckError) do |error|
        expect(error.message).to include("required FIPS security providers")
        expect(error.message).to include("missing provider \"LOGSTASH_MISSING_FIPS_PROVIDER\"")
        expect(error.message).to include("missing provider \"LOGSTASH_MISSING_JSSE_PROVIDER\"")
      end
    end
  end
end
