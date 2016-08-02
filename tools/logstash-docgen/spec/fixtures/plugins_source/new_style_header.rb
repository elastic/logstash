require_relative "base"

# encoding: utf-8
#
# This is a new test plugins
# with multiple line.

module LogStash module Inputs class Dummy < LogStash::Inputs::Base
  config_name "dummy"

  # option 1 description
  config :option1, :type => :boolean, :default => false

  # option 2 description
  config :option2, :type => :string, :default => "localhost"
end
