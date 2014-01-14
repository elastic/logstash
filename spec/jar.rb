require "insist"

describe "logstash jar features", :if => (__FILE__ =~ /file:.*!/) do
  let(:jar_root) { __FILE__.split("!").first + "!" }

  it "must be only run from a jar" do
    insist { __FILE__ } =~ /file:.*!/
  end

  it "must contain GeoLiteCity.dat" do
    path = File.join(jar_root, "GeoLiteCity.dat")
    insist { File }.exists?(path)
  end

  it "must contain vendor/ua-parser/regexes.yaml" do
    path = File.join(jar_root, "vendor/ua-parser/regexes.yaml")
    insist { File }.exists?(path)
  end

  it "must successfully load aws-sdk (LOGSTASH-1718)" do
    require "aws-sdk"
    # trigger autoload
    AWS::Errors
    AWS::Record
    AWS::Core::AsyncHandle
  end
end
