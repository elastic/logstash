# Copyright Elasticsearch B.V. and/or licensed to Elasticsearch B.V. under one
# or more contributor license agreements. Licensed under the Elastic License;
# you may not use this file except in compliance with the Elastic License.

require 'stud/try'

module LogStash module Helpers
  class LoggableTry < Stud::Try
    def initialize(logger, name)
      @logger = logger
      @name = name
    end

    def log_failure(exception, fail_count, message)
      @logger.warn("Attempt to #{@name} failed. #{message}", fail_count: fail_count, exception: exception.message)
    end
  end
end end
