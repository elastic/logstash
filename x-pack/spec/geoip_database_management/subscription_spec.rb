# # Copyright Elasticsearch B.V. and/or licensed to Elasticsearch B.V. under one
# # or more contributor license agreements. Licensed under the Elastic License;
# # you may not use this file except in compliance with the Elastic License.

require 'geoip_database_management/subscription'

describe LogStash::GeoipDatabaseManagement::Subscription, :aggregate_failures do
  let(:mock_state) { double("state", release!: nil) }
  let(:initial_value) { LogStash::GeoipDatabaseManagement::DbInfo::PENDING }

  subject(:subscription) { described_class.new(initial_value, mock_state) }

  context "#value" do
    context "blocking" do
      it 'yields the current value' do
        expect { |b| subscription.value(&b) }.to yield_with_args(initial_value)
      end
      it 'returns the result of the block' do
        return_value = Object.new
        expect(subscription.value { |_| return_value}).to equal return_value
      end
      context "under contention" do
        it 'allows many concurrent readers' do
          concurrency = 10

          start_latch = Concurrent::CountDownLatch.new(concurrency)
          release_latch = Concurrent::CountDownLatch.new(concurrency)
          finish_latch = Concurrent::CountDownLatch.new(concurrency)

          max_concurrent = Concurrent::AtomicFixnum.new

          threads = concurrency.times.map do |idx|
            Thread.new do
              Thread.current.abort_on_exception = true
              start_latch.count_down
              start_latch.wait(2) || fail("threads failed to start")
              subscription.value do |db_info|
                max_concurrent.increment

                release_latch.count_down
                release_latch.wait(2) || fail("threads failed to concurrently lock value (#{max_concurrent})")
              end
              finish_latch.count_down
              finish_latch.wait(2) || fail("failed to release")
            end
          end

          # cleanup threads
          deadline = Time.now + 10
          threads.each do |t|
            timeout_remaining = [deadline - Time.now, 0].max
            t.kill unless t.join(timeout_remaining)
          end

          expect(max_concurrent.value).to eq(concurrency)
        end

        # validates that #value with a block will prevent updates until control is returned.
        # sets up a sequence in which several readers get the initial value concurrently,
        # a writer contends for the lock and modifies the value, and subsequent readers get
        # the updated value.
        it 'read-write contention', aggregate_failures: true do

          pre_write_count = 3
          post_write_count = 7
          reader_count = pre_write_count + post_write_count

          readers_ready_latch = Concurrent::CountDownLatch.new(reader_count)
          writer_ready_event = Concurrent::Event.new
          pre_write_read_acquired_latch = Concurrent::CountDownLatch.new(pre_write_count)
          pre_write_read_released_latch = Concurrent::CountDownLatch.new(pre_write_count)
          pre_write_event = Concurrent::Event.new

          values = Queue.new

          threads = []

          # pre-write: acquire multiple locks, then signal writer and give it
          # a chance to contend for the lock before releasing
          pre_write_count.times do |idx|
            threads << Thread.new do
              Thread.current.abort_on_exception = true
              readers_ready_latch.count_down
              writer_ready_event.wait(2) || fail("writer failed to become ready")
              subscription.value do |db_info|
                pre_write_read_acquired_latch.count_down
                values << db_info

                # wait until writer has signaled that it is about to try to write
                pre_write_event.wait(2) || fail("writer failed to begin action")
                sleep(1) # wait long enough to ensure contention
                # ensure that the other readers are free to begin
                pre_write_read_released_latch.count_down
              end
            end
          end

          # post-write: wait until _just_ before the pre-write readers release their lock,
          # ensuring we are queued after the writer's blocked write.
          post_write_count.times do |idx|
            threads << Thread.new do
              Thread.current.abort_on_exception = true
              readers_ready_latch.count_down
              pre_write_read_released_latch.wait(10) || fail("pre-write readers failed to finish")
              subscription.value do |db_info|
                values << db_info
              end
            end
          end

          # write: wait until the pre-write readers have acquired the lock
          # before performing the write.
          updated_db_info = LogStash::GeoipDatabaseManagement::DbInfo.new(path: "/path/to/db")
          threads << Thread.new do
            Thread.current.abort_on_exception = true
            writer_ready_event.set
            readers_ready_latch.wait(10) || fail("readers never became ready")
            pre_write_read_acquired_latch.wait(10) || fail("pre reads never acquired")
            pre_write_event.set
            subscription.notify(updated_db_info)
          end

          # cleanup threads
          deadline = Time.now + 10
          threads.each do |t|
            timeout_remaining = [deadline - Time.now, 0].max
            t.kill unless t.join(timeout_remaining)
          end

          expect(values.size).to eq(pre_write_count + post_write_count)
          pre_write_count.times do
            expect(values.pop(true)).to equal initial_value
          end
          post_write_count.times do
            expect(values.pop(true)).to equal updated_db_info
          end
          expect(values).to be_empty
        end
      end
    end

    context "non-blocking" do
      it 'returns the current value' do
        expect(subscription.value).to equal initial_value
      end
    end
  end

  context '#release!' do
    it 'releases' do
      subscription.release!

      expect(mock_state).to have_received(:release!).with(subscription)
    end
  end

  context "#observe" do
    shared_examples "observation" do
      let!(:log) { Queue.new }

      it "observes construct, update, and expiry" do
        current_value = LogStash::GeoipDatabaseManagement::DbInfo.new(path: "/one/two")
        subscription.notify(current_value)
        expect(log).to be_empty

        subscription.observe(observer_spec)

        expect(log.size).to eq(1)
        expect(log.pop(true)).to eq([:construct, current_value])

        updated_value = LogStash::GeoipDatabaseManagement::DbInfo.new(path: "/three/four")
        subscription.notify(updated_value)
        expect(log.size).to eq(1)
        expect(log.pop(true)).to eq([:on_update, updated_value])

        expired_value = LogStash::GeoipDatabaseManagement::DbInfo::EXPIRED
        subscription.notify(expired_value)

        expect(log.size).to eq(1)
        expect(log.pop(true)).to eq([:on_expire])

        another_updated_value = LogStash::GeoipDatabaseManagement::DbInfo.new(path: "/five/six")
        subscription.notify(another_updated_value)
        expect(log.size).to eq(1)
        expect(log.pop(true)).to eq([:on_update, another_updated_value])
      end

      context 'when subscription was previously released' do
        before(:each) { subscription.release! }
        it 'prevents new observation' do
          expect { subscription.observe(observer_spec) }.to raise_exception(/released/)
          expect(log).to be_empty
        end
      end
    end

    context "when given a components hash" do
      let(:observer_spec) {
        {
          construct: ->(v) { log << [:construct, v]},
          on_update: ->(v) { log << [:on_update, v]},
          on_expire: ->( ) { log << [:on_expire]   },
        }
      }

      include_examples "observation"
    end

    context "when given an object that quacks like a SubscriptionObserver instance" do
      let(:observer_class) do
        Class.new do
          def initialize(log); @log = log; end
          def construct(v); @log << [:construct, v]; end
          def on_update(v); @log << [:on_update, v]; end
          def on_expire;    @log << [:on_expire];    end
        end
      end
      let(:observer_spec) { observer_class.new(log) }

      include_examples "observation"
    end
  end
end