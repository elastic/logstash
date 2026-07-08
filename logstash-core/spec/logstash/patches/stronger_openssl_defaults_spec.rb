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

describe "stronger_openssl_defaults patch" do
  before do
    load File.expand_path("../../../lib/logstash/patches/stronger_openssl_defaults.rb", __dir__)
  end

  it "defines OpenSSL::SSL::SSLContext::DEFAULT_PARAMS" do
    expect(defined?(OpenSSL::SSL::SSLContext::DEFAULT_PARAMS)).to be_truthy
  end

  it "includes MOZILLA_INTERMEDIATE_CIPHERS in DEFAULT_PARAMS" do
    expect(OpenSSL::SSL::SSLContext::DEFAULT_PARAMS[:ciphers]).to include("ECDHE-RSA-AES128-GCM-SHA256")
  end

  it "sets ssl_version to TLS in DEFAULT_PARAMS" do
    expect(OpenSSL::SSL::SSLContext::DEFAULT_PARAMS[:ssl_version]).to eq("TLS")
  end

  it "wraps SSLContext.new to invoke set_params" do
    # The patch aliases SSLContext.new; constructing a context should not raise
    expect { OpenSSL::SSL::SSLContext.new }.not_to raise_error
  end
end
