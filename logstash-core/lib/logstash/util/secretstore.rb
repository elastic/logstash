# encoding: utf-8

# Ruby helper to work with the secret store
module ::LogStash::Util::SecretStore

  java_import "org.logstash.secret.store.SecretStoreFactory"
  java_import "org.logstash.secret.SecretIdentifier"
  java_import "org.logstash.secret.store.SecureConfig"
  java_import "org.logstash.secret.cli.SecretStoreCli"

  # Return the configuration necessary to work with a secret store
  def self.get_config
    secure_config = SecureConfig.new
    secure_config.add("keystore.file", LogStash::SETTINGS.get_setting("keystore.file").value.chars)
    pass = ENV["LOGSTASH_KEYSTORE_PASS"]
    secure_config.add("keystore.pass", pass.chars) unless pass.nil?
    secure_config.add("keystore.classname", LogStash::SETTINGS.get_setting("keystore.classname").value.chars)
    secure_config
  end

  # Check to see if the secret store exists, return true if exists, false otherwise
  def self.exists?
    SecretStoreFactory.exists(get_config)
  end

  # Returns a org.logstash.secret.store.SecretStore if it exists, nil otherwise
  def self.get_if_exists
    SecretStoreFactory.load(get_config) if exists?
  end

  # Returns a org.org.logstash.secret.SecretIdentifier for use with the secret store
  def self.get_store_id(id)
    SecretIdentifier.new(id)
  end

end
