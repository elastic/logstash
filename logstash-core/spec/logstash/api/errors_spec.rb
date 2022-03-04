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

require "spec_helper"
require "logstash/api/errors"

describe LogStash::Api::ApiError do
  subject { described_class.new }

  it "#status_code returns 500" do
    expect(subject.status_code).to eq(500)
  end

  it "#to_hash return the message of the exception" do
    expect(subject.to_hash).to include(:message => "Api Error")
  end
end

describe LogStash::Api::NotFoundError do
  subject { described_class.new }

  it "#status_code returns 404" do
    expect(subject.status_code).to eq(404)
  end

  it "#to_hash return the message of the exception" do
    expect(subject.to_hash).to include(:message => "Not Found")
  end
end
