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
require "logstash/bootstrap_check/ssl_reload"
require "logstash/errors"

describe LogStash::BootstrapCheck::SslReload do
  let(:settings) { LogStash::SETTINGS.clone }

  after { LogStash::SETTINGS.reset }

  it "passes when ssl.reload.automatic is false" do
    settings.set("ssl.reload.automatic", false)
    settings.set("config.reload.automatic", false)
    expect { described_class.check(settings) }.not_to raise_error
  end

  it "passes when ssl.reload.automatic and config.reload.automatic are both true" do
    settings.set("ssl.reload.automatic", true)
    settings.set("config.reload.automatic", true)
    expect { described_class.check(settings) }.not_to raise_error
  end

  it "passes when CPM is enabled even if config.reload.automatic is false" do
    settings.set("ssl.reload.automatic", true)
    settings.set("config.reload.automatic", false)
    settings.set("xpack.management.enabled", true)
    expect { described_class.check(settings) }.not_to raise_error
  end

  it "raises BootstrapCheckError when config.reload.automatic is false and CPM is not enabled" do
    settings.set("ssl.reload.automatic", true)
    settings.set("config.reload.automatic", false)
    settings.set("xpack.management.enabled", false)
    expect { described_class.check(settings) }.to raise_error(
      LogStash::BootstrapCheckError,
      /ssl\.reload\.automatic.*config\.reload\.automatic/
    )
  end

  it "raises BootstrapCheckError on OSS where xpack.management.enabled is not registered" do
    allow(settings).to receive(:registered?).and_call_original
    allow(settings).to receive(:registered?).with("xpack.management.enabled").and_return(false)
    settings.set("ssl.reload.automatic", true)
    settings.set("config.reload.automatic", false)
    expect { described_class.check(settings) }.to raise_error(
      LogStash::BootstrapCheckError,
      /ssl\.reload\.automatic.*config\.reload\.automatic/
    )
  end
end
