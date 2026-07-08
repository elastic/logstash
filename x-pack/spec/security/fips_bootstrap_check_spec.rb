# Copyright Elasticsearch B.V. and/or licensed to Elasticsearch B.V. under one
# or more contributor license agreements. Licensed under the Elastic License;
# you may not use this file except in compliance with the Elastic License.

require "spec_helper"
require "logstash/environment"
require "logstash/settings"
require "logstash/runner"
require "security/extension"

describe LogStash::Security::FipsBootstrapCheck do
  subject(:check) { described_class.check(settings) }

  let(:settings) { LogStash::Runner::SYSTEM_SETTINGS.clone }

  before do
    LogStash::Security::Extension.new.additionals_settings(settings)
  end

  context "when FIPS mode is disabled" do
    it "does not perform any checks" do
      expect(::Java::java.security.Security).not_to receive(:getProviders)
      expect { check }.not_to raise_error
    end
  end

  # Stub the private check methods directly on the module to avoid requiring BC-FIPS JARs
  # on the classpath in non-FIPS CI runs.
  context "when FIPS mode is enabled" do
    before do
      settings.set("xpack.security.fips_mode.enabled", true)
    end

    let(:bcfips_provider) { double("BCFIPS provider", name: "BCFIPS", getVersionStr: "2.0.0") }
    let(:bcjsse_provider) { double("BCJSSE provider", name: "BCJSSE", getVersionStr: "2.0.0") }
    let(:sun_provider)    { double("SUN provider",    name: "SUN",    getVersionStr: "11") }

    def stub_all_checks_passing(provider_list: [bcfips_provider, bcjsse_provider, sun_provider])
      allow(described_class).to receive(:check_provider_ordering).and_return([])
      allow(described_class).to receive(:check_secure_random_provider).and_return([])
      allow(described_class).to receive(:check_fips_ready).and_return([])
      allow(described_class).to receive(:check_jruby_openssl_not_registered).and_return([])
      allow(::Java::java.security.Security).to receive(:getProviders).and_return(provider_list)
    end

    context "with a fully compliant FIPS environment" do
      before { stub_all_checks_passing }

      it "passes without error" do
        expect { check }.not_to raise_error
      end
    end

    context "with a fully compliant FIPS environment and matching required providers" do
      before do
        stub_all_checks_passing
        settings.set("xpack.security.fips_mode.required_providers", ["BCFIPS", "BCJSSE"])
      end

      it "passes without error" do
        expect { check }.not_to raise_error
      end
    end

    context "with a fully compliant FIPS environment and version-glob required providers" do
      before do
        stub_all_checks_passing
        settings.set("xpack.security.fips_mode.required_providers", ["BCFIPS:2.0.*", "BCJSSE:2.0.*"])
      end

      it "passes without error" do
        expect { check }.not_to raise_error
      end
    end

    context "when BCFIPS is not the first provider" do
      before do
        stub_all_checks_passing
        allow(described_class).to receive(:check_provider_ordering)
          .and_return(["BCFIPS must be the first Java security provider (observed: \"SUN\")"])
      end

      it "raises a BootstrapCheckError mentioning provider ordering" do
        expect { check }.to raise_error(LogStash::BootstrapCheckError, /BCFIPS must be the first Java security provider/)
      end
    end

    context "when SecureRandom is not backed by BCFIPS" do
      before do
        stub_all_checks_passing
        allow(described_class).to receive(:check_secure_random_provider)
          .and_return(["Java SecureRandom must be provided by BCFIPS (observed: \"SUN\")"])
      end

      it "raises a BootstrapCheckError mentioning SecureRandom" do
        expect { check }.to raise_error(LogStash::BootstrapCheckError, /SecureRandom must be provided by BCFIPS/)
      end
    end

    context "when BouncyCastle FIPS is not ready" do
      before do
        stub_all_checks_passing
        allow(described_class).to receive(:check_fips_ready)
          .and_return(["BouncyCastle FIPS is not ready"])
      end

      it "raises a BootstrapCheckError mentioning FIPS readiness" do
        expect { check }.to raise_error(LogStash::BootstrapCheckError, /BouncyCastle FIPS is not ready/)
      end
    end

    context "when JRuby OpenSSL provider is registered" do
      before do
        stub_all_checks_passing
        allow(described_class).to receive(:check_jruby_openssl_not_registered)
          .and_return(["The non-FIPS JRuby OpenSSL security provider must not be registered"])
      end

      it "raises a BootstrapCheckError mentioning the non-FIPS provider" do
        expect { check }.to raise_error(LogStash::BootstrapCheckError, /non-FIPS JRuby OpenSSL security provider must not be registered/)
      end
    end

    context "when JRuby OpenSSL provider is eligible for registration" do
      before do
        stub_all_checks_passing
        allow(described_class).to receive(:check_jruby_openssl_not_registered)
          .and_return(["The non-FIPS JRuby OpenSSL security provider is eligible for registration; set -Djruby.openssl.provider.register=false"])
      end

      it "raises a BootstrapCheckError mentioning provider.register flag" do
        expect { check }.to raise_error(LogStash::BootstrapCheckError, /jruby.openssl.provider.register=false/)
      end
    end

    context "when a required provider is missing" do
      before do
        stub_all_checks_passing
        settings.set("xpack.security.fips_mode.required_providers", ["LOGSTASH_MISSING_FIPS_PROVIDER"])
      end

      it "raises a BootstrapCheckError mentioning the missing provider" do
        expect { check }.to raise_error(LogStash::BootstrapCheckError, /missing provider "LOGSTASH_MISSING_FIPS_PROVIDER"/)
      end
    end

    context "when multiple checks fail simultaneously" do
      before do
        stub_all_checks_passing
        allow(described_class).to receive(:check_provider_ordering)
          .and_return(["BCFIPS must be the first Java security provider (observed: \"SUN\")"])
        allow(described_class).to receive(:check_jruby_openssl_not_registered)
          .and_return(["The non-FIPS JRuby OpenSSL security provider must not be registered"])
      end

      it "raises a single BootstrapCheckError listing all failures" do
        expect { check }.to raise_error(LogStash::BootstrapCheckError) do |error|
          expect(error.message).to include("BCFIPS must be the first Java security provider")
          expect(error.message).to include("non-FIPS JRuby OpenSSL security provider must not be registered")
        end
      end
    end
  end
end
