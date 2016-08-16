# encoding: utf-8
require "spec_helper"

DATA_DOUBLE = "data".freeze

# use a dummy NOOP output to test Outputs::Base
class LogStash::Codecs::NOOPAsync < LogStash::Codecs::Base
  attr_reader :last_result
  config_name "noop_async"

  def encode(event)
    @last_result = @on_event.call(event, DATA_DOUBLE)
  end
end

class LogStash::Codecs::NOOPSync < LogStash::Codecs::Base
  attr_reader :last_result
  config_name "noop_sync"

  def encode_sync(event)
    DATA_DOUBLE
  end
end

class LogStash::Codecs::NOOPMulti < LogStash::Codecs::Base
  attr_reader :last_result
  config_name "noop_multi"

  def encode_sync(event)
    DATA_DOUBLE
  end
end

describe LogStash::Codecs::Base do
  let(:params) { {} }
  subject(:instance) { klass.new(params.dup) }
  let(:event) { double("event") }
  let(:encoded_data) { DATA_DOUBLE }
  let(:encoded_tuple) { [event, encoded_data] }

  describe "encoding" do
    shared_examples "encoder types" do |codec_class|
      let(:klass) { codec_class }
      
      describe "#{codec_class}" do
        describe "multi_encode" do
          it "should return an array of [event,data] tuples" do
            expect(instance.multi_encode([event,event])).to eq([encoded_tuple, encoded_tuple])
          end
        end
        
        describe "#encode" do
          before do
            @result = nil
            instance.on_event do |event, data|
              @result = [event, data]
            end
            instance.encode(event)
          end
          
          it "should yield the correct result" do
            expect(@result).to eq(encoded_tuple)
          end
        end
      end
    end

    include_examples("encoder types", LogStash::Codecs::NOOPAsync)
    include_examples("encoder types", LogStash::Codecs::NOOPSync)
    include_examples("encoder types", LogStash::Codecs::NOOPMulti)
  end
end

                          
