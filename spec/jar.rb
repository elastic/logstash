require "insist"

describe "logstash jar features" do
  before :each do 
    @jar_root = __FILE__.split("!").first + "!"
  end

  it "must be only run from a jar" do
    insist { __FILE__ } =~ /file:.*!/
  end

  it "must contain GeoLiteCity.dat" do
    path = File.join(@jar_root, "GeoLiteCity.dat")
    insist { File }.exists?(path)
  end

  it "must contain vendor/ua-parser/regexes.yaml" do
    path = File.join(@jar_root, "vendor/ua-parser/regexes.yaml")
    insist { File }.exists?(path)
  end
end
