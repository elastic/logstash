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

# This class exists to quietly wrap a password string so that, when printed or
# logged, you don't accidentally print the password itself.

module LogStash; module Util
    java_import "co.elastic.logstash.api.Password" # class LogStash::Util::Password
    java_import "org.logstash.secret.password.PasswordValidator" # class LogStash::Util::PasswordValidator
    java_import "org.logstash.secret.password.PasswordPolicyType" # class LogStash::Util::PasswordPolicyType
    java_import "org.logstash.secret.password.PasswordPolicyParam" # class LogStash::Util::PasswordPolicyParam
end; end
