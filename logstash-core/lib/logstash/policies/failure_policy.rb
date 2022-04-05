module ::LogStash::Policies
  class FailurePolicy
    def on_fail
      raise "Not Implemented"
    end
  end
end