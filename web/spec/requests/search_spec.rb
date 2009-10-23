require File.join(File.dirname(__FILE__), '..', 'spec_helper.rb')

describe "/search" do
  before(:each) do
    @response = request("/search")
  end
end