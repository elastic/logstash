
RSpec.configure do |config|
  config.around(:each, verify_stubs: true) do |example|
    config.mock_with :rspec do |mocks|
      begin
        previous_verify = mockes.verify_partial_doubles
        mocks.verify_partial_doubles = true
        example.run
      ensure
        mocks.verify_partial_doubles = previous_verify
      end
    end
  end
end