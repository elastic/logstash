ROOT = File.expand_path(File.dirname(__FILE__))
$LOAD_PATH.unshift File.join(ROOT, 'lib')
Dir.glob('lib/**').each{ |d| $LOAD_PATH.unshift(File.join(ROOT, d)) }

require 'sinatra'
require 'app/root'
require 'app/stats'

env = ENV["RACK_ENV"].to_sym
set :environment, env

set :service, LogStash::Api::Service.instance

run LogStash::Api::Root

namespaces = { "/_stats" => LogStash::Api::Stats }

namespaces.each_pair do |namespace, app|
  map(namespace) do
    run app
  end
end
