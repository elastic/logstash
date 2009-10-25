# Go to http://wiki.merbivore.com/pages/init-rb
 
# Specify a specific version of a dependency
# dependency "RedCloth", "> 3.0"
dependency "merb-helpers", ">= 1.0.12"
dependency "merb-assets", ">= 1.0.12"

#  use_orm :none
use_test :rspec
use_template_engine :erb
 
Merb::Config.use do |c|
  c[:use_mutex] = false
  c[:session_store] = 'cookie'  # can also be 'memory', 'memcache', 'container', 'datamapper
  
  # cookie session store configuration
  c[:session_secret_key]  = '04d4714e97846aec300bc25b3526a9fb942d9e3d'  # required for cookie session store
  c[:session_id_key] = '_web_session_id' # cookie session id key, defaults to "_session_id"
end
 
Merb::BootLoader.before_app_loads do
  # This will get executed after dependencies have been loaded but before your app's classes have loaded.
end
 
Merb::BootLoader.after_app_loads do
  # This will get executed after your app's classes have been loaded.
  $search = LogStash::Net::Clients::Search.new("/opt/logstash/etc/logstashd.yaml")
end
