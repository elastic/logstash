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

# In FIPS mode, redirect jruby-openssl's crypto operations to the BCFIPS and
# BCJSSE providers so that all Ruby-level TLS and cryptography uses
# FIPS-validated modules instead of the non-FIPS BouncyCastle 1.84 bundled
# with jruby-openssl.
#
# This must run before any `require "openssl"` anywhere in the process, because
# SecurityHelper caches the provider at first initialization.
#
# Mechanism:
#   SecurityHelper.setSecurityProvider(provider) - routes MessageDigest, Cipher,
#     KeyFactory, KeyStore, Signature, etc. through the given provider.
#   -Djruby.openssl.ssl.provider=BCJSSE - routes SSLContext through BCJSSE
#     (which delegates to BCFIPS for its crypto).
#
# We do NOT set -Djruby.openssl.load.jars=false — jruby-openssl still loads BC
# 1.84 JARs for its internal class structure, but all JCE/JSSE operations are
# routed through BCFIPS/BCJSSE instead.
# We DO keep -Djruby.openssl.provider.register=false (set in bin/logstash.lib.sh)
# so BC 1.84 is never inserted into the JVM security provider list.

# Activate when BCFIPS is registered as the first JVM security provider.
# We key off provider presence rather than approved_only=true because we run
# C:HYBRID mode (matching Elasticsearch) which does not set approved_only.
bcfips_provider = java.security.Security.getProvider("BCFIPS")
return unless bcfips_provider && java.security.Security.getProviders.first&.getName == "BCFIPS"

# Route all JCE operations (Cipher, MessageDigest, KeyFactory, etc.) through BCFIPS.
org.jruby.ext.openssl.SecurityHelper.setSecurityProvider(bcfips_provider)

# Route SSLContext through BCJSSE (which uses BCFIPS for its underlying crypto).
# Only set if not already explicitly configured by the operator.
unless java.lang.System.getProperty("jruby.openssl.ssl.provider")
  java.lang.System.setProperty("jruby.openssl.ssl.provider", "BCJSSE")
end
