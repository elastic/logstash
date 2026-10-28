# Runs inside a Logstash image with bin/ruby. Checks that the default trust of the Ruby (jruby-openssl)
# and Java TLS stacks rejects a chain to emSign ECC Root CA - G3, while a store holding only that root accepts it.
# usage: ruby container_trust_check.rb FIXTURES_DIR
require 'openssl'

fixtures = ARGV[0]
load = ->(name) { OpenSSL::X509::Certificate.new(File.read(File.join(fixtures, name))) }
root = load['emsign-ecc-root-ca-g3.crt']
chain = [load['em-dv-tls-ca-g3b-emsign.crt'], load['emsign-root-tls-ca-g3-by-emsign-ecc-root-ca-g3.crt']]
failures = []

ruby_trusts = lambda do |store|
  store.time = Time.utc(2026, 10, 21)
  store.verify(chain[0], chain[1..])
end
default_store = OpenSSL::X509::Store.new.tap(&:set_default_paths)
root_store = OpenSSL::X509::Store.new.tap { |store| store.add_cert(root) }
failures << 'ruby control: chain does not validate against emSign ECC Root CA - G3 itself' unless ruby_trusts.call(root_store)
failures << 'ruby default store trusts a chain to emSign ECC Root CA - G3' if ruby_trusts.call(default_store)

factory = java.security.cert.CertificateFactory.getInstance('X.509')
to_java = ->(cert) { factory.generate_certificate(java.io.ByteArrayInputStream.new(cert.to_der.to_java_bytes)) }
java_chain = factory.generate_cert_path(chain.map(&to_java))
java_trusts = lambda do |anchors|
  params = java.security.cert.PKIXParameters.new(java.util.HashSet.new(anchors.map { |cert| java.security.cert.TrustAnchor.new(cert, nil) }))
  params.revocation_enabled = false
  params.date = java.util.Date.from(java.time.Instant.parse('2026-10-21T00:00:00Z'))
  java.security.cert.CertPathValidator.getInstance('PKIX').validate(java_chain, params)
  true
rescue java.security.cert.CertPathValidatorException
  false
end
tmf = javax.net.ssl.TrustManagerFactory.getInstance(javax.net.ssl.TrustManagerFactory.getDefaultAlgorithm)
tmf.java_send(:init, [java.security.KeyStore], nil)
default_anchors = tmf.trust_managers.first.accepted_issuers.to_a
failures << "java default trust has only #{default_anchors.size} anchors" if default_anchors.size < 100
failures << 'java control: chain does not validate against emSign ECC Root CA - G3 itself' unless java_trusts.call([to_java[root]])
failures << 'java default trust store trusts a chain to emSign ECC Root CA - G3' if java_trusts.call(default_anchors)

puts "  ruby store #{ENV['SSL_CERT_FILE'] || OpenSSL::X509::DEFAULT_CERT_FILE}, java #{java.lang.System.getProperty('java.runtime.version')}"
failures.each { |failure| puts "  FAIL #{failure}" }
exit(failures.empty? ? 0 : 1)
