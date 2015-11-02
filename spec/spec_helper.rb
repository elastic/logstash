# encoding: utf-8
require_relative 'coverage_helper'
# In order to archive an expected coverage analysis we need to eager load
# all logstash code base, otherwise it will not get a good analysis.
CoverageHelper.eager_load if ENV['COVERAGE']

require "logstash/devutils/rspec/spec_helper"
require_relative "./support/matchers"

def installed_plugins
  Gem::Specification.find_all.select { |spec| spec.metadata["logstash_plugin"] }.map { |plugin| plugin.name }
end
