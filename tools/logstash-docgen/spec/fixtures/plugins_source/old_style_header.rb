require_relative "base"
require_relative "config_from_mixin"

# encoding: utf-8
#
# This is a new test plugins
# with multiple line.

class LogStash::Inputs::Dummy < LogStash::Inputs::Base
  config_name "dummy"

  include ConfigFromMixin

  # option 1 description
  config :option1, :type => :boolean, :default => false

  # option 2 description
  config :option2, :type => :string, :default => "localhost"
end
