# Copyright Elasticsearch B.V. and/or licensed to Elasticsearch B.V. under one
# or more contributor license agreements. Licensed under the Elastic License;
# you may not use this file except in compliance with the Elastic License.
#
require 'monitoring/inputs/metrics'
require 'logstash-core'
require 'logstash/compiler'
require 'logstash/lir_serializer'

module LogStash; module Inputs; class Metrics; class StateEvent;
  class XPackLIRSerializer < LIRSerializer
    attr_reader :lir_pipeline
    
    def self.serialize(lir_pipeline)
      self.new(lir_pipeline).serialize
    end
    
    def initialize(lir_pipeline)
      @lir_pipeline = lir_pipeline
    end
end; end; end; end; end;
