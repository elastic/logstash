# encoding: utf-8
require "logstash/java_integration"

describe "java_integration" do
  if LogStash::Environment.jruby?

    context "Java List" do
      it "should report as Ruby Array" do
        expect(Java::JavaUtil::ArrayList.new.is_a?(Array)).to be true
        expect(Java::JavaUtil::Vector.new.is_a?(Array)).to be true
      end
    end

    context "Java Map" do
      it "should report as Ruby Hash" do
        expect(Java::JavaUtil::HashMap.new.is_a?(Hash)).to be true
        expect(Java::JavaUtil::LinkedHashMap.new.is_a?(Hash)).to be true
        expect(Java::JavaUtil::TreeMap.new.is_a?(Hash)).to be true
      end
    end

    context "Ruby Hash" do
      it "should report as Java Map" do
        expect(Hash === Java::JavaUtil::LinkedHashMap.new).to be true
        expect(Hash === Java::JavaUtil::HashMap.new).to be true
        expect(Hash === Java::JavaUtil::TreeMap.new).to be true
      end
    end

    context "Ruby Array" do
      it "should report as Java List" do
        expect(Array === Java::JavaUtil::ArrayList.new).to be true
        expect(Array === Java::JavaUtil::Vector.new).to be true
      end
    end

    context "Java Map merge" do
      # see https://github.com/jruby/jruby/issues/1249

      it "should support HashMap merge" do
        expect(Java::JavaUtil::HashMap.new.merge(:a => 1)).to eq({:a => 1})
      end

      it "should support LinkedHashMap merge" do
        expect(Java::JavaUtil::LinkedHashMap.new.merge(:a => 1)).to eq({:a => 1})
      end

      it "should support TreeMap merge" do
        expect(Java::JavaUtil::TreeMap.new.merge(:a => 1)).to eq({:a => 1})
      end
    end
  end
end