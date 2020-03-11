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

# This is a patch for childprocess and this is due to ruby-cabin/fpm interaction.
# When we use the logger.pipe construct and the IO reach EOF we close the IO.
# The problem Childprocess will try to flush to it and hit an IOError making the software crash in JRuby 9k.
#
# In JRuby 1.7.25 we hit a thread death.
#
module ChildProcess
  module JRuby
    class Pump
      alias_method :old_pump, :pump

      def ignore_close_io
        old_pump
      rescue IOError
      end

      alias_method :pump, :ignore_close_io
    end
  end
end
