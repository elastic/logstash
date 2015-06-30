# we need to call exit explicity  in order to set the proper exit code, otherwise
# most common CI systems can not know whats up with this tests.
require_relative "default_plugins"
require_relative "license"

namespace "license" do

  desc "run core specs"
  task "core" do
    require 'yaml'
    generate_license_information
  end

end

task "license" => [ "license:core" ]
