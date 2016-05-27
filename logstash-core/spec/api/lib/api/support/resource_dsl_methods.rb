module ResourceDSLMethods
  # Convert a nested hash to a mapping of key paths to expected classes
  def hash_to_mapping(h, path=[], mapping={})
    h.each do |k,v|
      if v.is_a?(Hash)
        hash_to_mapping(v, path + [k], mapping)
      else
        full_path = path + [k]
        mapping[full_path] = v
      end
    end
    mapping
  end

  def test_api(expected, path)
    context "GET #{path}" do
      let(:payload) { LogStash::Json.load(last_response.body) }
      
      before(:all) do
        do_request { get path }
      end      
      
      it "should respond OK" do
        expect(last_response).to be_ok
      end
      
      hash_to_mapping(expected).each do |resource_path,klass|
        dotted = resource_path.join(".")
        
        it "should set '#{dotted}' at '#{path}' to be a '#{klass}'" do
          expect(last_response).to be_ok # fail early if need be
          resource_path_value = resource_path.reduce(payload) do |acc,v|
            expect(acc.has_key?(v)).to eql(true), "Expected to find value '#{v}' in structure '#{acc}', but could not. Payload was '#{payload}'"
            acc[v]
          end
          expect(resource_path_value).to be_a(klass), "could not find '#{dotted}' in #{payload}"
        end
      end
    end

    yield if block_given? # Add custom expectations
  end

  def test_api_and_resources(expected)
    test_api(expected, "/")

    expected.keys.each do |key|
      test_api({key => expected[key]}, "/#{key}")
    end
  end
end
