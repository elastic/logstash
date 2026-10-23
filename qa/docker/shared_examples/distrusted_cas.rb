DISTRUSTED_CAS_CHECK = <<~'RUBY'
  require 'openssl'
  intermediate, cross_signed_root = ARGV.map { |pem| OpenSSL::X509::Certificate.new(pem) }

  store = OpenSSL::X509::Store.new
  store.set_default_paths
  store.time = Time.utc(2026, 10, 21)
  bundle = File.read(ENV['SSL_CERT_FILE'] || OpenSSL::X509::DEFAULT_CERT_FILE)
  control = OpenSSL::X509::Certificate.new(bundle[/-----BEGIN CERTIFICATE-----.*?-----END CERTIFICATE-----/m])
  puts "ruby control #{store.verify(control) ? 'TRUSTED' : 'REJECTED'}"
  puts "ruby emsign #{store.verify(intermediate, [cross_signed_root]) ? 'TRUSTED' : 'REJECTED'}"

  factory = java.security.cert.CertificateFactory.getInstance('X.509')
  to_java = ->(cert) { factory.generate_certificate(java.io.ByteArrayInputStream.new(cert.to_der.to_java_bytes)) }
  cacerts = java.security.KeyStore.getInstance('PKCS12')
  java.io.FileInputStream.new("#{java.lang.System.getProperty('java.home')}/lib/security/cacerts").tap { |stream| cacerts.load(stream, nil) }.close
  puts "java anchors #{cacerts.size}"
  params = java.security.cert.PKIXParameters.new(cacerts)
  params.revocation_enabled = false
  params.date = java.util.Date.from(java.time.Instant.parse('2026-10-21T00:00:00Z'))
  begin
    java.security.cert.CertPathValidator.getInstance('PKIX').validate(factory.generate_cert_path([intermediate, cross_signed_root].map(&to_java)), params)
    puts 'java emsign TRUSTED'
  rescue java.security.cert.CertPathValidatorException => e
    puts "java emsign REJECTED #{e.message}"
  end
RUBY

shared_examples_for 'it distrusts emSign ECC Root CA - G3' do |flavor|
  before do
    @image = find_image(flavor)
    @container = create_container(@image, {})
  end

  after do
    cleanup_container(@container)
  end

  it 'is rejected by the Ruby and Java TLS stacks' do
    pems = %w(em-dv-tls-ca-g3b-emsign.crt emsign-root-tls-ca-g3-by-emsign-ecc-root-ca-g3.crt).map do |name|
      File.read(File.join(FIXTURES_DIR, 'distrusted_ca_certs', name))
    end
    output = @container.exec(['/usr/share/logstash/bin/ruby', '-e', DISTRUSTED_CAS_CHECK, '--', *pems])[0].join

    aggregate_failures do
      expect(output).to include('ruby control TRUSTED')
      expect(output).to include('ruby emsign REJECTED')
      expect(output).to match(/java anchors [1-9]/)
      expect(output).to include('java emsign REJECTED')
    end
  end
end
