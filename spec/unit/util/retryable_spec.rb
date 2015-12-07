require "logstash/util/retryable"

describe LogStash::Retryable do
  class C
    include LogStash::Retryable
  end

  class E < StandardError; end;
  class F < StandardError; end;

  subject {C.new}

  context "with default fixed 1 second retry sleep" do

    it "should execute once" do
      expect(subject).to receive(:sleep).never
      expect(subject.retryable(:rescue => nil){|i| expect(i).to eq(0); "foo"}).to eq("foo")
    end

    it "should not retry on non rescued exceptions" do
      i = 0
      expect(subject).to receive(:sleep).never
      expect{subject.retryable(:rescue => E){i += 1; raise F}}.to raise_error(F)
      expect(i).to eq(1)
    end

    it "should execute once and retry once by default" do
      i = 0
      expect(subject).to receive(:sleep).once.with(1)
      expect{subject.retryable{i += 1; raise E}}.to raise_error(E)
      expect(i).to eq(2)
    end

    it "should retry on rescued exceptions" do
      i = 0
      expect(subject).to receive(:sleep).once.with(1)
      expect{subject.retryable(:rescue => E){i += 1; raise E}}.to raise_error(E)
      expect(i).to eq(2)
    end

    it "should retry indefinitely" do
      i = 0
      expect(subject).to receive(:sleep).exactly(50).times.with(1)
      expect{subject.retryable(:tries => 0, :rescue => E){i += 1; raise i <= 50 ? E : F}}.to raise_error(F)
    end

    it "should execute once and retry once by default and execute on_retry callback" do
      i = 0
      callback_values = []

      callback = lambda do |retry_count, e|
        callback_values << [retry_count, e]
      end

      expect(subject).to receive(:sleep).once.with(1)

      expect do
        subject.retryable(:on_retry => callback){i += 1; raise E}
      end.to raise_error

      expect(i).to eq(2)

      expect(callback_values.size).to eq(1)
      expect(callback_values[0][0]).to eq(1)
      expect(callback_values[0][1]).to be_a(E)
    end

    it "should execute once and retry n times" do
      i = 0
      n = 3
      expect(subject).to receive(:sleep).exactly(n).times.with(1)
      expect{subject.retryable(:tries => n){i += 1; raise E}}.to raise_error(E)
      expect(i).to eq(n + 1)
    end

    it "should execute once and retry n times and execute on_retry callback" do
      i = 0
      n = 3
      callback_values = []

      callback = lambda do |retry_count, e|
        callback_values << [retry_count, e]
      end

      expect(subject).to receive(:sleep).exactly(n).times.with(1)

      expect do
        subject.retryable(:tries => n, :on_retry => callback){i += 1; raise E}
      end.to raise_error

      expect(i).to eq(n + 1)

      expect(callback_values.size).to eq(n)
      n.times.each do |j|
        expect(callback_values[j].first).to eq(j + 1)
        expect(callback_values[j].last).to be_a(E)
      end
    end
  end

  context "with exponential backoff" do

    it "should execute once and retry once with base sleep by default" do
      expect(subject).to receive(:sleep).once.with(2)
      expect do
        subject.retryable(:base_sleep => 2, :max_sleep => 10){raise E}
      end.to raise_error(E)
    end

    it "should execute once and retry n times with exponential backoff sleep" do
      n = 3
      s = 0.5

      n.times.each do |i|
        expect(subject).to receive(:sleep).once.with(s * (2 ** i)).ordered
      end
      expect do
        subject.retryable(:tries => n, :base_sleep => s, :max_sleep => 100){raise E}
      end.to raise_error(E)
    end

    it "should execute once and retry n times with exponential backoff sleep capping at max_sleep" do
      n = 20
      base_sleep = 0.1
      max_sleep = 1

      expect(subject).to receive(:sleep).once.with(0.1).ordered
      expect(subject).to receive(:sleep).once.with(0.2).ordered
      expect(subject).to receive(:sleep).once.with(0.4).ordered
      expect(subject).to receive(:sleep).once.with(0.8).ordered
      (n - 4).times.each do |i|
        expect(subject).to receive(:sleep).once.with(1).ordered
      end
      expect do
        subject.retryable(:tries => n, :base_sleep => base_sleep, :max_sleep => max_sleep){raise E}
      end.to raise_error(E)
    end
  end
end