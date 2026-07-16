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

require "openssl"

def build_cert(public_key, subject, issuer_name, issuer_cert)
  cert = OpenSSL::X509::Certificate.new
  cert.version    = 2
  cert.serial     = OpenSSL::BN.rand(128, 0)
  cert.subject    = subject
  cert.issuer     = issuer_name || subject
  cert.public_key = public_key
  cert.not_before = Time.now - 1
  cert.not_after  = Time.now + 3650 * 24 * 60 * 60
  cert
end

def generate_ca
  key  = OpenSSL::PKey::RSA.new(2048)
  name = OpenSSL::X509::Name.parse("/CN=Logstash IT Test CA")
  cert = build_cert(key.public_key, name, nil, nil)
  ef   = OpenSSL::X509::ExtensionFactory.new(cert, cert)
  cert.add_extension(ef.create_extension("basicConstraints", "CA:TRUE", true))
  cert.add_extension(ef.create_extension("keyUsage", "cRLSign,keyCertSign", true))
  cert.sign(key, OpenSSL::Digest::SHA256.new)
  [key, cert]
end

def generate_leaf(ca_key, ca_cert)
  key  = OpenSSL::PKey::RSA.new(2048)
  name = OpenSSL::X509::Name.parse("/CN=localhost")
  cert = build_cert(key.public_key, name, ca_cert.subject, ca_cert)
  ef   = OpenSSL::X509::ExtensionFactory.new(ca_cert, cert)
  cert.add_extension(ef.create_extension("subjectAltName", "IP:127.0.0.1,DNS:localhost"))
  cert.add_extension(ef.create_extension("basicConstraints", "CA:FALSE", true))
  cert.sign(ca_key, OpenSSL::Digest::SHA256.new)
  [key, cert]
end

def write_cert_pair(dir, base, key, cert)
  File.write(File.join(dir, "#{base}.key"), key.to_pem)
  File.write(File.join(dir, "#{base}.crt"), cert.to_pem)
end

# Create a PKCS12 truststore containing one or more CA certificates.
# ca_certs may be a single OpenSSL::X509::Certificate or an array of them.
# Uses the Java KeyStore API directly (available in JRuby without keytool).
def create_truststore(ca_certs, path, password)
  ks = java.security.KeyStore.getInstance("PKCS12")
  ks.load(nil, nil)
  cf = java.security.cert.CertificateFactory.getInstance("X.509")
  Array(ca_certs).each_with_index do |cert, i|
    java_cert = cf.generateCertificate(java.io.ByteArrayInputStream.new(cert.to_der.to_java_bytes))
    ks.setCertificateEntry("ca-#{i}", java_cert)
  end
  fos = java.io.FileOutputStream.new(path)
  begin
    ks.store(fos, password.chars.to_java(:char))
  ensure
    fos.close
  end
end
