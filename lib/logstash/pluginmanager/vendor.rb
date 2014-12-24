require 'logstash/json'
require 'logstash/util/filetools'

module LogStash::PluginManager::Vendor

  def self.setup_hook
    Gem.post_install do |gem_installer|
      next if ENV['VENDOR_SKIP'] == 'true'
      vendor_file = ::File.join(gem_installer.gem_dir, 'vendor.json')
      if ::File.exist?(vendor_file)
        vendor_file_content = IO.read(vendor_file)
        file_list = LogStash::Json.load(vendor_file_content)
        LogStash::Util::FileTools.process_downloads(file_list, ::File.join(gem_installer.gem_dir, 'vendor'))
      end
    end
  end
end
