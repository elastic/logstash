# encoding: utf-8
require "logstash/instrument/periodic_poller/load_average"
describe LogStash::Instrument::PeriodicPoller::LoadAverage do
  subject { described_class.create }

  context "on mocked system" do
    context "on Linux" do
      before do
        expect(LogStash::Environment).to receive(:windows?).and_return(false)
        expect(LogStash::Environment).to receive(:linux?).and_return(true)
      end

      context "when it can read the file" do
        let(:proc_loadavg) { "0.00 0.01 0.05 3/180 29727" }

        before do
          expect(::File).to receive(:read).with("/proc/loadavg").and_return(proc_loadavg)
        end

        it "return the 3 load average from `/proc/loadavg`" do
          avg_1m, avg_5m, avg_15m = proc_loadavg.chomp.split(" ")

          expect(subject.get).to include(:"1m" => avg_1m.to_f, :"5m" => avg_5m.to_f, :"15m" => avg_15m.to_f)
        end
      end
    end

    context "on windows" do
      before do
        expect(LogStash::Environment).to receive(:windows?).and_return(true)
      end

      it "Xreturns nil" do
        expect(subject.get).to be_nil
      end
    end

    context "on other" do
      before do
        expect(LogStash::Environment).to receive(:windows?).and_return(false)
        expect(LogStash::Environment).to receive(:linux?).and_return(false)
      end

      context "when 'OperatingSystemMXBean.getSystemLoadAverage' return something" do
        let(:load_avg) { 5 }

        before do
          expect(ManagementFactory).to receive(:getOperatingSystemMXBean).and_return(double("OperatingSystemMXBean", :getSystemLoadAverage => load_avg))
        end

        it "returns the value" do
          expect(subject.get).to include(:"1m" => 5)
        end
      end

      context "when 'OperatingSystemMXBean.getSystemLoadAverage' doesn't return anything" do
        before do
          expect(ManagementFactory).to receive(:getOperatingSystemMXBean).and_return(double("OperatingSystemMXBean", :getSystemLoadAverage => nil))
        end

        it "returns nothing" do
          expect(subject.get).to be_nil
        end
      end
    end
  end

  # Since we are running this on macos and linux I think it make sense to have real test
  # insteadof only mock
  context "real system" do
    if LogStash::Environment.linux?
      context "Linux" do
        it "returns the load avg" do
          expect(subject.get).to include(:"1m" => a_kind_of(Numeric), :"5m" => a_kind_of(Numeric), :"15m" => a_kind_of(Numeric))
        end
      end
    elsif LogStash::Environment.windows?
      context "window" do
        it "returns nothing" do
          expect(subject.get).to be_nil
        end
      end
    else
      context "Other" do
        it "returns 1m only" do
          expect(subject.get).to include(:"1m" => a_kind_of(Numeric))
        end
      end
    end
  end
end
