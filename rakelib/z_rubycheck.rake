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

if ENV['USE_RUBY'] != '1'
  if RUBY_ENGINE != "jruby" or Gem.ruby !~ /vendor\/jruby\/bin\/jruby/
    puts "Restarting myself under Vendored JRuby (currently #{RUBY_ENGINE} #{RUBY_VERSION})" if ENV['DEBUG']

    # Make sure we have JRuby, then rerun ourselves under jruby.
    Rake::Task["vendor:jruby"].invoke
    jruby = File.join("bin", "ruby")
    rake = File.join("vendor", "jruby", "bin", "rake")

    # if required at this point system gems can be installed using the system_gem task, for example:
    # Rake::Task["vendor:system_gem"].invoke(jruby, "ffi", "1.9.6")

    # Ignore Environment JAVA_OPTS
    ENV["JAVA_OPTS"] = ""
    exec(jruby, "-J-Xmx1g", "-S", rake, *ARGV)
  end
end

def discover_rake()
  Dir.glob('vendor', 'bundle', 'rake')
end
