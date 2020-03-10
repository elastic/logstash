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

# Helper module for all tests
require "flores/random"
require "fileutils"
require "zip"
require "stud/temporary"
require "socket"
require "ostruct"

def wait_for_port(port, retry_attempts)
  tries = retry_attempts
  while tries > 0
    if is_port_open?(port)
      break
    else
      sleep 1
    end
    tries -= 1
  end
end

def is_port_open?(port)
  TCPSocket.open("localhost", port) do
    return true
  end
rescue Errno::ECONNREFUSED, Errno::EHOSTUNREACH
  return false
end

def send_data(port, data)
  socket = TCPSocket.new("127.0.0.1", port)
  socket.puts(data)
  socket.flush
  socket.close
end

def config_to_temp_file(config)
  f = Stud::Temporary.file
  f.write(config)
  f.close
  f.path
end

def random_port
  # 9600-9700 is reserved in Logstash HTTP server, so we don't want that
  Flores::Random.integer(9701..15000)
end

class Pack
  PLUGINS_PATH = "logstash"
  DEPENDENCIES_PATH = File.join("logstash", "dependencies")
  GEM_EXTENSION = ".gem"

  def initialize(target)
    @target = target
  end

  def plugins
    @plugins ||= extract_gems_data(File.join(@target, PLUGINS_PATH))
  end

  def dependencies
    @dependencies ||= extract_gems_data(File.join(@target, DEPENDENCIES_PATH))
  end

  def glob_gems
    "*#{GEM_EXTENSION}"
  end

  def extract_gems_data(path)
    Dir.glob(File.join(path, glob_gems)).collect { |gem_file| extract_gem_data_from_file(gem_file) }
  end

  def extract_gem_data_from_file(gem_file)
    gem = File.basename(gem_file.downcase, GEM_EXTENSION)

    parts = gem.split("-")

    if gem.match(/java/)
      platform = parts.pop
      version = parts.pop
      name = parts.join("-")

      OpenStruct.new(:name => name, :version => version, :platform => platform)
    else
      version = parts.pop
      name = parts.join("-")

      OpenStruct.new(:name => name, :version => version, :platform => nil)
    end
  end
end

def extract(source, target, pattern = nil)
  raise "Directory #{target} exist" if ::File.exist?(target)
  Zip::File.open(source) do |zip_file|
    zip_file.each do |file|
      path = ::File.join(target, file.name)
      FileUtils.mkdir_p(::File.dirname(path))
      zip_file.extract(file, path) if pattern.nil? || pattern =~ file.name
    end
  end
end

def unpack(zip)
  target = Stud::Temporary.pathname
  extract(zip, target)
  Pack.new(target)
end
