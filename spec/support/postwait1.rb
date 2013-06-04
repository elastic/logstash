require "test_utils"

describe "some stuff" do
  extend LogStash::RSpec

  config <<-'CONFIG'
    filter {
      grep {
          tags => web
          drop => false
          add_field => [ "application", "web" ]
      }
     
      mutate {
          tags => web
          #replace => [ "message", "%{request}" ]
          add_field => [ "message", "%{request}" ]
      }
    }
  CONFIG

  sample("tags" => [ "web" ], "request" => "hello") do
    insist { subject["tags"] }.include?("web")
    insist { subject["message"] } == "hello"
  end
end
