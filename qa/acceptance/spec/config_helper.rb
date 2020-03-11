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

require "json"

module SpecsHelper

  def self.configure(vagrant_boxes)
    setup_config = JSON.parse(File.read(File.join(File.dirname(__FILE__), "..", "..", ".vm_ssh_config")))
    boxes        = vagrant_boxes.inject({}) do |acc, v|
      acc[v.name] = v.type
      acc
    end
    ServiceTester.configure do |config|
      config.servers = []
      config.lookup  = {}
      setup_config.each do |host_info|
        next unless boxes.keys.include?(host_info["host"])
        url = "#{host_info["hostname"]}:#{host_info["port"]}"
        config.servers << url
        config.lookup[url] = {"host" => host_info["host"], "type" => boxes[host_info["host"]] }
      end
    end
  end
end
