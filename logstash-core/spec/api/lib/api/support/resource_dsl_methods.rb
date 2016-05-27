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
      
      hash_to_mapping(expected).each do |path,klass|
        dotted = path.join(".")
        
        it "should set '#{dotted}' to be a '#{klass}'" do
          path_value = path.reduce(payload) {|acc,v| acc[v]}
          expect(path_value).to be_a(klass), "could not find '#{dotted}' in #{payload}"
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
