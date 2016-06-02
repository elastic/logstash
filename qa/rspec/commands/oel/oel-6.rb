# encoding: utf-8
require_relative "../base"
require_relative "../redhat"

module ServiceTester
  class Oel6Commands < RedhatCommands
    include ::ServiceTester::InitD
  end
end
