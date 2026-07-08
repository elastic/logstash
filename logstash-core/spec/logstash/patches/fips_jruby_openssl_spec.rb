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

describe "fips_jruby_openssl patch" do
  let(:ssl_provider_prop) { "jruby.openssl.ssl.provider" }
  let(:mock_bcfips) { double("BCFIPSProvider", getName: "BCFIPS") }
  let(:mock_sun)    { double("SUNProvider",    getName: "SUN") }

  def load_patch
    load File.expand_path("../../../lib/logstash/patches/fips_jruby_openssl.rb", __dir__)
  end

  context "when BCFIPS is not the first registered provider" do
    before do
      allow(java.security.Security).to receive(:getProvider).with("BCFIPS").and_return(nil)
      allow(java.security.Security).to receive(:getProviders).and_return([mock_sun])
    end

    it "does not call setSecurityProvider" do
      expect(org.jruby.ext.openssl.SecurityHelper).not_to receive(:setSecurityProvider)
      load_patch
    end

    it "does not set jruby.openssl.ssl.provider" do
      expect(java.lang.System).not_to receive(:setProperty).with(ssl_provider_prop, anything)
      load_patch
    end
  end

  context "when BCFIPS is present but not the first provider" do
    before do
      allow(java.security.Security).to receive(:getProvider).with("BCFIPS").and_return(mock_bcfips)
      allow(java.security.Security).to receive(:getProviders).and_return([mock_sun, mock_bcfips])
    end

    it "does not call setSecurityProvider" do
      expect(org.jruby.ext.openssl.SecurityHelper).not_to receive(:setSecurityProvider)
      load_patch
    end
  end

  context "when BCFIPS is the first registered provider (FIPS mode)" do
    before do
      allow(java.security.Security).to receive(:getProvider).with("BCFIPS").and_return(mock_bcfips)
      allow(java.security.Security).to receive(:getProviders).and_return([mock_bcfips, mock_sun])
      allow(java.lang.System).to receive(:getProperty).with(ssl_provider_prop).and_return(nil)
      allow(org.jruby.ext.openssl.SecurityHelper).to receive(:setSecurityProvider)
      allow(java.lang.System).to receive(:setProperty)
    end

    it "passes the BCFIPS provider to SecurityHelper" do
      load_patch
      expect(org.jruby.ext.openssl.SecurityHelper).to have_received(:setSecurityProvider).with(mock_bcfips)
    end

    it "sets jruby.openssl.ssl.provider to BCJSSE" do
      load_patch
      expect(java.lang.System).to have_received(:setProperty).with(ssl_provider_prop, "BCJSSE")
    end

    it "does not override jruby.openssl.ssl.provider if already set" do
      allow(java.lang.System).to receive(:getProperty).with(ssl_provider_prop).and_return("SomeOtherProvider")
      load_patch
      expect(java.lang.System).not_to have_received(:setProperty).with(ssl_provider_prop, anything)
    end
  end
end
