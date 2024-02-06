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

require_relative "./commands/debian"
require_relative "./commands/ubuntu"
require_relative "./commands/redhat"
require_relative "./commands/suse"
require_relative "./commands/opensuse"
require_relative "./commands/centos/centos-6"
require_relative "./commands/oel/oel-6"
require_relative "./commands/suse/sles-11"

require "forwardable"
require "open3"

OS_RELEASE_PATH = "/etc/os-release"

class HostFacts
  def initialize()
    @os_release = {}
    begin
      os_release_hash = File.foreach(OS_RELEASE_PATH).each_with_object({}) do |line, hash|
        next if line.strip.empty?
        key, value = line.strip.split("=")
        @os_release[key] = value.tr('"', "")
      end
    rescue Errno::ENOENT
      puts "File not found: #{OS_RELEASE_PATH}"
    rescue Errno::EACCES
      puts "Permission denied to read file: #{OS_RELEASE_PATH}"
    rescue StandardError => e
      puts "Error parsing content of #{OS_RELEASE_PATH}: #{e.message}"
    end
  end

  def orig_name
    # e.g. openSUSE Leap
    @os_release["NAME"]
  end

  def name
    # e.g. opensuse leap
    @os_release["NAME"].downcase
  end

  def id
    # e.g. ubuntu for Ubuntu 22.04, or debian for Debian 11, or centos for centos-7
    @os_release["ID"].downcase
  end

  def id_like
    # e.g. "rhel fedora" for centos-7
    @os_release["ID_LIKE"].downcase
  end

  def version_codename
    # e.g. jammy for Ubuntu 22.04, or bullseye for Debian 11, unset for RHEL
    @os_release["VERSION_CODENAME"].downcase
  end

  def version_id
    # e.g. 22.04 for Ubuntu jammy, 11 for Debian Bullseye, 8.x for RHEL 8 distros
    @os_release["VERSION_ID"].downcase
  end

  def human_name
    if self.version_id
      "#{self.orig_name} #{self.version_id}"
    else
      orig_name
    end
  end
end

module ServiceTester
  # An artifact is the component being tested, it's able to interact with
  # a destination machine by holding a client and is basically provides all
  # necessary abstractions to make the test simple.
  class Artifact
    extend Forwardable
    def_delegators :@client, :installed?, :removed?, :running?

    attr_reader :client

    def initialize(options = {})
      @options = options
      @hostfacts = HostFacts.new()
      @client = CommandsFactory.fetch(@hostfacts)
      @skip_jdk_infix = false
    end

    def hostname
      `hostname`.chomp
    end

    def human_name
      @hostfacts.human_name
    end

    def hosts
      [@hostname]
    end

    def name
      "logstash"
    end

    def start_service
      client.start_service(name)
    end

    def stop_service
      client.stop_service(name)
    end

    def install(options = {})
      base = options.fetch(:base, ServiceTester::Base::LOCATION)
      @skip_jdk_infix = options.fetch(:skip_jdk_infix, false)
      filename = filename(options)
      package = client.package_for(filename, @skip_jdk_infix, base)
      client.install(package)
    end

    def write_default_pipeline()
      # defines a minimal pipeline so that the service is able to start
      client.write_pipeline("input { heartbeat {} } output { null {} }")
    end

    def uninstall
      client.uninstall(name)
    end

    def run_command_in_path(cmd)
      client.run_command_in_path(cmd)
    end

    def run_command(cmd)
      client.run_command(cmd)
    end

    def plugin_installed?(name, version = nil)
      client.plugin_installed?(name, version)
    end

    def gem_vendored?(gem_name)
      client.gem_vendored?(gem_name)
    end

    def download(from, to)
      client.download(from, to)
    end

    def replace_in_gemfile(pattern, replace)
      client.replace_in_gemfile(pattern, replace)
    end

    def delete_file(path)
      client.delete_file(path)
    end

    def to_s
      "Artifact #{name}@#{host}"
    end

    private

    def filename(options = {})
      snapshot = options.fetch(:snapshot, true)
      "logstash-#{options[:version]}#{(snapshot ? "-SNAPSHOT" : "")}"
    end
  end

  # Factory of commands used to select the right clients for a given type of OS
  class CommandsFactory
    def self.fetch(hostfacts)
      case
      when hostfacts.name.include?("ubuntu")
        return UbuntuCommands.new
      when hostfacts.name.include?("debian")
        return DebianCommands.new
      when hostfacts.name.include?("opensuse")
        return OpenSuseCommands.new
      when hostfacts.name.include?("red hat")
        return RedhatCommands.new
      when hostfacts.id_like.include?("rhel"), hostfacts.id_like.include?("fedora")
        # covers Oracle Linux, CentOS, Rocky Linux, Amazon Linux
        # TODO add specific commands (e.g. to use dnf instead of yum where applicable)
        return RedhatCommands.new
      end
    end
  end
end
