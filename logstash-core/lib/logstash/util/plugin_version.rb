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

require 'rubygems/version'
require 'forwardable'

module LogStash::Util
  class PluginVersion
    extend Forwardable
    include Comparable

    GEM_NAME_PREFIX = 'logstash'

    def_delegators :@version, :to_s
    attr_reader :version

    def initialize(*options)
      if options.size == 1 && options.first.is_a?(Gem::Version)
        @version = options.first
      else
        @version = Gem::Version.new(options.join('.'))
      end
    end

    def self.find_version!(name)
      begin
        spec = Gem::Specification.find_by_name(name)
        if spec.nil?
          # Checking for nil? is a workaround for situations where find_by_name
          # is not able to find the real spec, as for example with pre releases
          # of plugins
          spec = Gem::Specification.find_all_by_name(name).first
        end
        new(spec.version)
      rescue Gem::LoadError
        # Rescuing the LoadError and raise a Logstash specific error.
        # Likely we can't find the gem in the current GEM_PATH
        raise LogStash::PluginNoVersionError
      end
    end

    def self.find_plugin_version!(type, name)
      plugin_name = [GEM_NAME_PREFIX, type, name].join('-')
      find_version!(plugin_name)
    end

    def <=>(other)
      version <=> other.version
    end

    private

    def self.build_from_spec(spec)
      new(spec.version)
    end
  end
end
