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

require "java"

# This block is used to load Logstash's Java libraries when using a Ruby entrypoint and
# LS_JARS_LOADED is not globally set.
# Currently this happens when using the `bin/rspec` executable to invoke specs instead of the JUnit
# wrapper.
unless $LS_JARS_LOADED
  jar_path = File.join(File.dirname(File.dirname(__FILE__)), "jars")
  Dir.glob("#{jar_path}/*.jar") do |jar|
    load jar
  end
  java_import org.logstash.RubyUtil
end
