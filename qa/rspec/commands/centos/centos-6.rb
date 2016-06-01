# encoding: utf-8
require_relative "../base"
require_relative "../redhat"

module ServiceTester
  class Centos6Commands < RedhatCommands
      include ::ServiceTester::InitD
  end
end
