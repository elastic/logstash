# Licensed to Elasticsearch B.V. under one or more contributor
# license agreements. See the NOTICE file distributed with
# this work for additional information regarding copyright
# ownership. Elasticsearch B.V. licenses this file to you under
# the Apache License, Version 2.0 (the "License"); you may
# not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#  http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing,
# software distributed under the License is distributed on an
# "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
# KIND, either express or implied.  See the License for the
# specific language governing permissions and limitations
# under the License.

# Patch to replace the usage of STDERR and STDOUT
# see: https://github.com/elastic/logstash/issues/5912
module LogStash
  class NullLogger
    def self.debug(message)
    end
  end

  # Puma uses by default the STDERR an the STDOUT for all his error
  # handling, the server class accept custom a events object that can accept custom io object,
  # so I just wrap the logger into an IO like object.
  class IOWrappedLogger
    def initialize(new_logger)
      @logger_lock = Mutex.new
      @logger = new_logger
    end

    def sync=(v)
      # noop
    end

    def logger=(logger)
      @logger_lock.synchronize { @logger = logger }
    end

    def puts(str)
      # The logger only accept a str as the first argument
      @logger_lock.synchronize { @logger.debug(str.to_s) }
    end
    alias_method :write, :puts
    alias_method :<<, :puts
  end

end

# Reopen the puma class to create a scoped STDERR and STDOUT
# This operation is thread safe since its done at the class level
# and force JRUBY to flush his classes cache.
module Puma
  STDERR = LogStash::IOWrappedLogger.new(LogStash::NullLogger)
  STDOUT = LogStash::IOWrappedLogger.new(LogStash::NullLogger)
end
