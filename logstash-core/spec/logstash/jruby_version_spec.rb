require 'spec_helper'


describe "JRuby Version" do
  it "should break on JRuby version change" do
    # This spec will break upon JRuby version change to make sure we
    # verify if resolv.rb has been fixed in Jruby so we can get rid of
    # lib/logstash/patches/resolv.rb.
    # ref:
    #   https://github.com/logstash-plugins/logstash-filter-dns/issues/51
    #   https://github.com/jruby/jruby/pull/5722
    expect(JRUBY_VERSION).to eq("9.2.7.0")
  end
end

