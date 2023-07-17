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

require_relative '../../../logstash-core/lib/logstash-core.rb'

# Base class for a service like Kafka, ES, Logstash
class Service

  attr_reader :settings

  def initialize(name, settings)
    @name = name
    @settings = settings
    @setup_script = File.expand_path("../#{name}_setup.sh", __FILE__)
    @teardown_script = File.expand_path("../#{name}_teardown.sh", __FILE__)
  end

  def setup
    puts "Setting up #{@name} service"
    if File.exist?(@setup_script)
      `#{Shellwords.escape(@setup_script)}`
      raise "#{@setup_script} FAILED with exit status #{$?}" unless $?.success?
    else
      puts "Setup script not found for #{@name}"
    end
    puts "#{@name} service setup complete"
  end

  def teardown
    puts "Tearing down #{@name} service"
    if File.exist?(@teardown_script)
      `#{Shellwords.escape(@teardown_script)}`
      raise "#{@teardown_script} FAILED with exit status #{$?}" unless $?.success?
    else
      puts "Teardown script not found for #{@name}"
    end
    puts "#{@name} service teardown complete"
  end
end
