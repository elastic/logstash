require "logstash/patches"

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
end
