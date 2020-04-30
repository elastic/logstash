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

require_relative "service"

# This is a registry used in Fixtures so a test can get back any service class
# at runtime
# All new services should register here
class ServiceLocator
  FILE_PATTERN = "_service.rb"

  def initialize(settings)
    @services = {}
    available_services do |name, klass|
      @services[name] = klass.new(settings)
    end
  end

  def get_service(name)
    @services.fetch(name)
  end

  def available_services
    Dir.glob(File.join(File.dirname(__FILE__), "*#{FILE_PATTERN}")).each do |f|
      require f
      basename = File.basename(f).gsub(/#{FILE_PATTERN}$/, "")
      service_name = basename.downcase
      klass = Object.const_get("#{service_name.capitalize}Service")
      yield service_name, klass
    end
  end
end
