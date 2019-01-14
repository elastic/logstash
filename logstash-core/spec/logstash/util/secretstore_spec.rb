require "logstash/util/secretstore"
require "logstash/settings"

describe LogStash::Util::SecretStore do

  subject {LogStash::Util::SecretStore}

  describe "with missing keystore" do
    before :each do
      LogStash::SETTINGS.set("keystore.file", File.join(File.dirname(__FILE__), "nothing_here"))
    end

    it "should be not exist" do
      expect(subject.exists?).to be_falsy
      expect(subject.get_if_exists).to be_nil
    end
  end

  describe "with implicit password keystore" do
    before :each do
      LogStash::SETTINGS.set("keystore.file", File.join(File.dirname(__FILE__), "../../../src/test/resources/logstash.keystore.with.default.pass"))
    end

    it "should be readable" do
      expect(subject.get_if_exists.list).to include(subject.get_store_id("keystore.seed"))
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
        expect(subject.get_if_exists.list).to include(subject.get_store_id("keystore.seed"))
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
        expect {subject.get_if_exists}.to raise_error.with_message(/Can not access Logstash keystore/)
      end
    end

    describe "and missing password" do
      it "should be not readable" do
        expect {subject.get_if_exists}.to raise_error.with_message(/Could not determine keystore password/)
      end
    end
  end

end