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

require_relative "../services/service_locator"
require_relative '../specs/spec_helper'

# A class that holds all fixtures for a given test file. This deals with
# bootstrapping services, dealing with config files, inputs etc
class Fixture
  FIXTURES_DIR = File.expand_path(File.join("..", "..", "fixtures"), __FILE__)

  attr_reader :input
  attr_reader :actual_output
  attr_reader :test_dir
  attr_reader :settings

  class TemplateContext
    attr_reader :options

    def initialize(options)
      @options = options
    end

    def get_binding
      binding
    end
  end

  def initialize(test_file_location)
    @test_file_location = test_file_location
    @settings = TestSettings.new(@test_file_location)
    @service_locator = ServiceLocator.new(@settings)
    setup_services unless serverless?
    @input = File.join(FIXTURES_DIR, @settings.get("input")) if @settings.is_set?("input")
    @actual_output = @settings.get("actual_output")
  end

  def config(node = "root", options = nil)
    if node == "root"
      config = @settings.get("config")
    else
      config = @settings.get("config")[node]
    end

    if options != nil
      ERB.new(config, trim_mode: "-").result(TemplateContext.new(options).get_binding)
    else
      config
    end
  end

  def get_service(name)
    @service_locator.get_service(name)
  end

  def teardown
    puts "Tearing down services"
    services = @settings.get("services")
    services.each do |name|
      @service_locator.get_service(name).teardown
    end
  end

  def setup_services
    puts "Setting up services"
    services = @settings.get("services")
    services.each do |name|
      @service_locator.get_service(name).setup
    end
    if @settings.is_set?("setup_script")
      puts "Setting up test specific fixtures"
      script = File.join(FIXTURES_DIR, @settings.get("setup_script"))
      `#{script}`
    end
  end
end
