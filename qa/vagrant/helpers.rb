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

require "open3"
require "bundler"
require_relative "command"

module LogStash
  class VagrantHelpers

    def self.halt(machines=[], options={})
      debug = options.fetch(:debug, false)
      CommandExecutor.run!("vagrant halt #{machines.join(' ')}", debug)
    end

    def self.destroy(machines=[], options={})
      debug = options.fetch(:debug, false)
      CommandExecutor.run!("vagrant destroy --force #{machines.join(' ')}", debug) 
    end

    def self.bootstrap(machines=[], options={})
      debug = options.fetch(:debug, false)
      CommandExecutor.run!("vagrant up #{machines.join(' ')}", debug)
    end

    def self.save_snapshot(machine="")
      CommandExecutor.run!("vagrant snapshot save #{machine} #{machine}-snapshot")
    end

    def self.restore_snapshot(machine="")
      CommandExecutor.run!("vagrant snapshot restore #{machine} #{machine}-snapshot")
    end

    def self.fetch_config
      machines = CommandExecutor.run!("vagrant status --machine-readable").stdout.split("\n").select { |l| l.include?("state,running") }.map { |r| r.split(',')[1]}
      CommandExecutor.run!("vagrant ssh-config #{machines.join(' ')}")
    end

    def self.parse(lines)
      hosts, host = [], {}
      lines.each do |line|
        if line.match(/Host\s(.*)$/)
          host = { :host => line.gsub("Host","").strip }
        elsif line.match(/HostName\s(.*)$/)
          host[:hostname] = line.gsub("HostName","").strip
        elsif line.match(/Port\s(.*)$/)
          host[:port]     = line.gsub("Port","").strip
        elsif line.empty?
          hosts << host
          host = {}
        end
      end
      hosts << host
      hosts
    end
  end
end
