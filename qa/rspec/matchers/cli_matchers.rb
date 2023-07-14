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

RSpec::Matchers.define :be_successful do
  match do |actual|
    actual.exit_status == 0
  end
end

RSpec::Matchers.define :fail_and_output do |expected_output|
  match do |actual|
    actual.exit_status == 1 && actual.stderr =~ expected_output
  end
end

RSpec::Matchers.define :run_successfully_and_output do |expected_output|
  match do |actual|
    (actual.exit_status == 0 || actual.exit_status.nil?) && actual.stdout =~ expected_output
  end
end

RSpec::Matchers.define :have_installed? do |name, *args|
  match do |actual|
    version = args.first
    actual.plugin_installed?(name, version)
  end
end

RSpec::Matchers.define :install_successfully do
  match do |cmd|
    expect(cmd).to run_successfully_and_output(/Installation successful/)
  end
end
