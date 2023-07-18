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

require "logstash/settings"

java_import "org.logstash.secret.store.SecretStoreExt"

describe SecretStoreExt do
  subject {SecretStoreExt}
  let(:settings) { LogStash::SETTINGS.clone }

  describe "with missing keystore" do
    before :each do
      settings.set("keystore.file", File.join(File.dirname(__FILE__), "nothing_here"))
    end

    it "should be not exist" do
      expect(subject.exists(settings.get_setting("keystore.file").value, settings.get_setting("keystore.classname").value)).to be_falsey
      expect(subject.getIfExists(settings.get_setting("keystore.file").value, settings.get_setting("keystore.classname").value)).to be_nil
    end
  end

  describe "with implicit password keystore" do
    before :each do
      settings.set("keystore.file", File.join(File.dirname(__FILE__), "../../../src/test/resources/logstash.keystore.with.default.pass"))
    end

    it "should be readable" do
      expect(subject.getIfExists(settings.get_setting("keystore.file").value, settings.get_setting("keystore.classname").value).list).to include(subject.get_store_id("keystore.seed"))
    end
  end

  describe "with explicit password keystore" do
    before :each do
      settings.set("keystore.file", File.join(File.dirname(__FILE__), "../../../src/test/resources/logstash.keystore.with.defined.pass"))
    end

    describe "and correct password" do
      before do
        ENV['LOGSTASH_KEYSTORE_PASS'] = "mypassword"
      end

      after do
        ENV.delete('LOGSTASH_KEYSTORE_PASS')
      end

      it "should be readable" do
        expect(subject.getIfExists(settings.get_setting("keystore.file").value, settings.get_setting("keystore.classname").value).list).to include(subject.get_store_id("keystore.seed"))
      end
    end

    describe "and wrong password" do
      before do
        ENV['LOGSTASH_KEYSTORE_PASS'] = "not_the_correct_password"
      end

      after do
        ENV.delete('LOGSTASH_KEYSTORE_PASS')
      end

      it "should be not readable" do
        expect {subject.getIfExists(settings.get_setting("keystore.file").value, settings.get_setting("keystore.classname").value)}.to raise_error.with_message(/Can not access Logstash keystore/)
      end
    end

    describe "and missing password" do
      it "should be not readable" do
        expect {subject.getIfExists(settings.get_setting("keystore.file").value, settings.get_setting("keystore.classname").value)}.to raise_error.with_message(/Could not determine keystore password/)
      end
    end
  end
end
