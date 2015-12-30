# encoding: utf-8
require "spec_helper"
require "logstash/util/wrapped_synchronous_queue"

describe LogStash::Util::WrappedSynchronousQueue do
 context "#offer" do
   context "queue is blocked" do
     it "fails and give feedback" do
       expect(subject.offer("Bonjour", 2)).to be_falsey
     end
   end

   context "queue is not blocked" do
     before do
       @consumer = Thread.new { loop { subject.take } }
       sleep(0.1)
     end

     after do
       @consumer.kill
     end
     
     it "inserts successfully" do
       expect(subject.offer("Bonjour", 20)).to be_truthy
     end
   end
 end
end
