ROOT = File.expand_path(File.dirname(__FILE__))
$LOAD_PATH.unshift File.join(ROOT, 'lib')
Dir.glob('lib/**').each{ |d| $LOAD_PATH.unshift(File.join(ROOT, d)) }

require 'sinatra'
require 'app/root'
require 'app/modules/stats'
require 'app/modules/node'
require 'app/modules/node_stats'
require 'app/modules/plugins'

env = ENV["RACK_ENV"].to_sym
set :environment, env

set :service, LogStash::Api::Service.instance

configure do
  enable :logging
end
run LogStash::Api::Root

namespaces = { "/_node" => LogStash::Api::Node,
               "/_node/stats" => LogStash::Api::NodeStats,
               "/_stats" => LogStash::Api::Stats,
               "/_plugins" => LogStash::Api::Plugins }

namespaces.each_pair do |namespace, app|
  map(namespace) do
    run app
  end
end
