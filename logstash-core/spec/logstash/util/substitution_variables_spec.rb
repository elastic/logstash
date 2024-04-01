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
require "logstash/util/substitution_variables"

describe LogStash::Util::SubstitutionVariables do

  let(:substitution_var_test_class) { Class.new { extend LogStash::Util::SubstitutionVariables } }

  describe "replace placeholder" do

    it "doesn't take into count if ${VAR} is in the comment" do
      config_with_commented_var_line = 'tcp {
          port => 12345 #"${TCP_PROD_PORT}"
          #"${TCP_DEV_PORT}"
        }'
      expect(substitution_var_test_class.replace_placeholders(config_with_commented_var_line))
        .to eq("tcp {\nport => 12345 \n}")
    end

  end

  describe "exclude config comments" do

    it "doesn't exclude comments if config string dosn't contain ${VAR}" do
      single_line_config = "{ sleep { time => 1 } }"
      multiline_config = "stdout {
        codec => rubydebug
      }"
      expect(substitution_var_test_class.exclude_config_comments(single_line_config)).to eq(single_line_config)
      expect(substitution_var_test_class.exclude_config_comments(multiline_config)).to eq(multiline_config)
    end

    it "removes the line value if commented" do
      config_with_commented_var_line = 'tcp {
          port => 12345
          #"${TCP_PORT}"
        }'
      expect(substitution_var_test_class.exclude_config_comments(config_with_commented_var_line))
        .to eq("tcp {\nport => 12345\n}")
    end

    it "wipes out comments if config string contains ${VAR}" do
      config_with_var_and_comment = 'elasticsearch {
      	hosts => ["${ES_DEV_HOST}"] # use ["${ES_PROD_HOST}"] for production
        index => "%{[some_field][sub_field]}-%{+YYYY.MM.dd}"
      }' # value of the output
      expected = "elasticsearch {\nhosts => [\"${ES_DEV_HOST}\"] \nindex => \"%{[some_field][sub_field]}-%{+YYYY.MM.dd}\"\n}"
      expect(substitution_var_test_class.exclude_config_comments(config_with_var_and_comment))
        .to eq(expected)
    end
  end
end