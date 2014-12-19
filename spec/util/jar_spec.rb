require "spec_helper"

describe "logstash jar features", :if => (__FILE__ =~ /file:.*!/) do

  let(:jar_root) { __FILE__.split("!").first + "!" }

  it "is only run from a jar" do
    expect(__FILE__).to match(/file:.*!/)
  end

  context "dependencies" do
    it "contains the GeoLiteCity.dat" do
      path = File.join(jar_root, "GeoLiteCity.dat")
      expect(File.exists?(path)).to be_true
    end

    it "contais vendor/ua-parser/regexes.yaml" do
      path = File.join(jar_root, "vendor/ua-parser/regexes.yaml")
      expect(File.exists?(path)).to be_true
    end
  end

  it "must successfully load aws-sdk (LOGSTASH-1718)" do
    require "aws-sdk"
    # trigger autoload
    AWS::Errors
    AWS::Record
    AWS::Core::AsyncHandle
  end
end
