

# Ruby 1.8.7 added String#start_with? - monkeypatch the
# String class if it isn't supported (<= ruby 1.8.6)
if !String.instance_methods.include?("start_with?")
  class String
    def start_with?(str)
      return self[0 .. (str.length-1)] == str
    end
  end
end

