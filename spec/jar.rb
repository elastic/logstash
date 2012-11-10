require "insist"

describe "logstash jar features" do
  before :each do 
    @jar_root = __FILE__.split("!").first + "!"
  end

  it "must contain GeoLiteCity.dat" do
    path = File.join(@jar_root, "GeoLiteCity.dat")
    insist { File }.exists?(path)
  end
end
