# encoding: utf-8
RSpec.configure do |config|
  if RbConfig::CONFIG["host_os"] != "linux"
    exclude_tags = { :linux => true }
  end

  config.filter_run_excluding exclude_tags
end
