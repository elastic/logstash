# encoding: utf-8
require "socket"
require "logstash/patches"
require "flores/pki"

describe "OpenSSL defaults" do
  subject { OpenSSL::SSL::SSLContext.new }

  # OpenSSL::SSL::SSLContext#ciphers returns an array of 
  # [ [ ciphername, version, bits, alg_bits ], [ ... ], ... ]
 
  # List of cipher names
  let(:ciphers) { subject.ciphers.map(&:first) }

  # List of cipher encryption bit strength. 
  let(:encryption_bits) { subject.ciphers.map { |_, _, _, a| a } }

  it "should not include any export ciphers" do
    # SSLContext#ciphers returns an array of [ciphername, tlsversion, key_bits, alg_bits]
    # Let's just check the cipher names
    expect(ciphers).not_to be_any { |name| name =~ /EXPORT/ || name =~ /^EXP/ }
  end

  it "should not include any weak ciphers (w/ less than 128 bits in encryption algorithm)" do
    # SSLContext#ciphers returns an array of [ciphername, tlsversion, key_bits, alg_bits]
    expect(encryption_bits).not_to be_any { |bits| bits < 128 }
  end

  it "should not include a default `verify_mode`" do
    expect(OpenSSL::SSL::SSLContext::DEFAULT_PARAMS[:verify_mode]).to eq(nil)
  end

  context "SSLSocket" do
    # Code taken from the flores library by @jordansissels,
    # https://github.com/jordansissel/ruby-flores/blob/master/spec/flores/pki_integration_spec.rb
    # since these helpers were created to fix this particular issue
    let(:csr) { Flores::PKI::CertificateSigningRequest.new }
    # Here, I use a 1024-bit key for faster tests. 
    # Please do not use such small keys in production.
    let(:key_bits) { 1024 }
    let(:key) { OpenSSL::PKey::RSA.generate(key_bits, 65537) }
    let(:certificate_duration) { Flores::Random.number(1..86400) }

    context "with self-signed client/server certificate" do
      let(:certificate_subject) { "CN=server.example.com" }
      let(:certificate) { csr.create }

      # Returns [socket, address, port]
      let(:listener) { Flores::Random.tcp_listener }
      let(:server) { listener[0] }
      let(:server_address) { listener[1] }
      let(:server_port) { listener[2] }

      let(:server_context) { OpenSSL::SSL::SSLContext.new }
      let(:client_context) { OpenSSL::SSL::SSLContext.new }

      before do
        csr.subject = certificate_subject
        csr.public_key = key.public_key
        csr.start_time = Time.now
        csr.expire_time = csr.start_time + certificate_duration
        csr.signing_key = key
        csr.want_signature_ability = true

        server_context.cert = certificate
        server_context.key = key

        client_store = OpenSSL::X509::Store.new
        client_store.add_cert(certificate)
        client_context.cert_store = client_store
        client_context.verify_mode = OpenSSL::SSL::VERIFY_PEER

        ssl_server = OpenSSL::SSL::SSLServer.new(server, server_context)
        Thread.new do
          begin
            ssl_server.accept
          rescue => e
            puts "Server accept failed: #{e}"
          end
        end
      end

      it "should successfully connect as a client" do
        socket = TCPSocket.new(server_address, server_port)
        ssl_client = OpenSSL::SSL::SSLSocket.new(socket, client_context)
        expect { ssl_client.connect }.not_to raise_error
      end
    end
  end
end
