class App < Sinatra::Application

  get "/hi" do
    "Hello world"
  end

  get "/" do
    "logstash - foo - bar"
  end

end
