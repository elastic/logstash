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

# Implementation of ChildProcess::JRuby::Process#pid depends heavily on
# what Java SDK is being used; here, we look it up once at load, then
# override that method with an implementation that works on modern Javas
# if necessary.
#
# This patch can be removed when the upstream childprocess gem supports Java 9+
# https://github.com/enkessler/childprocess/pull/141
normalised_java_version_major = java.lang.System.get_property("java.version")
                                    .slice(/^(1\.)?([0-9]+)/, 2)
                                    .to_i

if normalised_java_version_major >= 9
  $stderr.puts("patching childprocess for Java9+ support...")
  ChildProcess::JRuby::Process.class_exec do
    def pid
      @process.pid
    rescue java.lang.UnsupportedOperationException => e
      raise NotImplementedError, "pid is not supported on this platform: #{e.message}"
    end
  end
end
