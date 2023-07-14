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

# This is needed because some of the plugins have weird declaration in their header files
# so I make sure the basic namespaces are correctly setup.
module LogStash
  module Codecs; end
  module Inputs; end
  module Output; end
end

module LogStash module Docgen
  # Since we can use ruby code to generate some of the options
  # like the allowed values we need to actually ask the class to return the
  # evaluated values and another process will merge the values with the extracted
  # description. IE: Some plugins uses constant to define the list of valid values.
  class DynamicParser
    def initialize(context, file, klass_name)
      @file = file
      @klass_name = klass_name
      @context = context
    end

    def parse
      # If any errors is raised here it will be taken care by the `generator`,
      # most errors should be missings jars or bad requires.
      require @file

      klass.get_config.each do |name, attributes|
        @context.add_config_attributes(name, attributes)
      end
    end

    # Find all the modules included by the specified class
    # and use `source_location` to find the actual file on disk.
    # We need to cleanup the values for evaluated modules or system module.
    # `included_modules` will return the list of module in the order they appear.
    # this is important because modules can override the documentation of some
    # option.
    def extract_sources_location
      klass.ancestors
        .collect { |m| m.instance_methods.collect { |method| m.instance_method(method).source_location } + m.methods.collect { |method| m.method(method).source_location } }
        .flatten
        .compact
        .uniq
        .reject { |source| !source.is_a?(String) || source == "(eval)" }
    end

    def klass
      @klass_name.split('::').inject(Object) do |memo, name|
        memo = memo.const_get(name); memo
      end
    end
  end
end end
