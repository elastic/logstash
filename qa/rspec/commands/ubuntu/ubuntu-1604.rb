# encoding: utf-8
require_relative "../base"
require_relative "../ubuntu"

module ServiceTester
  class Ubuntu1604Commands < UbuntuCommands
      include ::ServiceTester::SystemD
  end
end
