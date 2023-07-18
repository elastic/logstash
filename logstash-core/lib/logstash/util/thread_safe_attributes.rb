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

module LogStash
  module Util
    # @api internal
    module ThreadSafeAttributes
      # Thread-safe lazy initialized attribute with a given (variable) name.
      def lazy_init_attr(attribute, variable: "@#{attribute}".to_sym, &block)
        raise ArgumentError.new("invalid attribute name: #{attribute}") unless attribute.match? /^[_A-Za-z]\w*$/
        raise ArgumentError.new('no block given') unless block_given?
        send(:define_method, attribute.to_sym) do
          if instance_variable_defined?(variable)
            instance_variable_get(variable)
          else
            LogStash::Util.synchronize(self) do
              if instance_variable_defined?(variable)
                instance_variable_get(variable)
              else
                instance_variable_set(variable, instance_eval(&block))
              end
            end
          end
        end
      end
    end
  end
end
