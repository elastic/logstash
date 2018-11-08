require "logstash/settings"

java_import "org.logstash.secret.store.SecretStoreExt"

describe SecretStoreExt do

  subject {SecretStoreExt}

  describe "with missing keystore" do
    before :each do
      LogStash::SETTINGS.set("keystore.file", File.join(File.dirname(__FILE__), "nothing_here"))
    end

    it "should be not exist" do
      expect(subject.exists(LogStash::SETTINGS.get_setting("keystore.file").value, LogStash::SETTINGS.get_setting("keystore.classname").value)).to be_falsy
      expect(subject.getIfExists(LogStash::SETTINGS.get_setting("keystore.file").value, LogStash::SETTINGS.get_setting("keystore.classname").value)).to be_nil
    end
  end

  describe "with implicit password keystore" do
    before :each do
      LogStash::SETTINGS.set("keystore.file", File.join(File.dirname(__FILE__), "../../../src/test/resources/logstash.keystore.with.default.pass"))
    end

    it "should be readable" do
      expect(subject.getIfExists(LogStash::SETTINGS.get_setting("keystore.file").value, LogStash::SETTINGS.get_setting("keystore.classname").value).list).to include(subject.get_store_id("keystore.seed"))
    end
  end

  describe "with explicit password keystore" do
    before :each do
      LogStash::SETTINGS.set("keystore.file", File.join(File.dirname(__FILE__), "../../../src/test/resources/logstash.keystore.with.defined.pass"))
    end

    describe "and correct password" do
      before do
        ENV['LOGSTASH_KEYSTORE_PASS'] = "mypassword"
      end

      after do
        ENV.delete('LOGSTASH_KEYSTORE_PASS')
      end

      it "should be readable" do
        expect(subject.getIfExists(LogStash::SETTINGS.get_setting("keystore.file").value, LogStash::SETTINGS.get_setting("keystore.classname").value).list).to include(subject.get_store_id("keystore.seed"))
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
        expect {subject.getIfExists(LogStash::SETTINGS.get_setting("keystore.file").value, LogStash::SETTINGS.get_setting("keystore.classname").value)}.to raise_error.with_message(/Can not access Logstash keystore/)
      end
    end

    describe "and missing password" do
      it "should be not readable" do
        expect {subject.getIfExists(LogStash::SETTINGS.get_setting("keystore.file").value, LogStash::SETTINGS.get_setting("keystore.classname").value)}.to raise_error.with_message(/Could not determine keystore password/)
      end
    end
  end
end