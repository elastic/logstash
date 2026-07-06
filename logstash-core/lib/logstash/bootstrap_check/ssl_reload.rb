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

module LogStash module BootstrapCheck
  # Validates that ssl.reload.automatic is only enabled with a compatible
  # reload mode. Centralized Pipeline Management flips config.reload.automatic
  # to true in its own bootstrap check; this check defers to that case via
  # the xpack.management.enabled flag to avoid ordering coupling.
  class SslReload
    def self.check(settings)
      return unless settings.get("ssl.reload.automatic")
      return if settings.get("config.reload.automatic")
      # xpack.management.enabled is only registered when x-pack is loaded (non-OSS).
      return if settings.registered?("xpack.management.enabled") && settings.get("xpack.management.enabled")
      raise LogStash::BootstrapCheckError,
        "`ssl.reload.automatic: true` requires `config.reload.automatic: true` " \
        "or Centralized Pipeline Management to be enabled."
    end
  end
end end
