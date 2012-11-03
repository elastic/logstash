require "insist"

describe "logstash jar features" do
  before :each do 
    @jar_root = __FILE__.split("!").first + "!"
  end

  it "must contain GeoCityLite.dat" do
    path = File.join(@jar_root, "GeoCityLite.dat")
    insist { File }.exists?(path)
  end
end
