require "insist"

describe "web tests" do
  context "rack rubygem" do
    it "must be available" do
      require "rack"
    end
  end
end
