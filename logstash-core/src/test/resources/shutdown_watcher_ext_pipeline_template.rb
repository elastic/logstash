pipeline = Object.new
reporter = Object.new
snapshot = Object.new
inflight_count = java.util.concurrent.atomic.AtomicInteger.new
snapshot.define_singleton_method(:inflight_count) do
  inflight_count.increment_and_get + 1
end
threads = {}
snapshot.define_singleton_method(:stalling_threads) do
  threads
end
snapshot.define_singleton_method(:to_s) do
  "inflight_count=>" + inflight_count.get.to_s + ", stalling_threads_info=>{...}"
end
reporter.define_singleton_method(:snapshot) do
  snapshot
end
pipeline.define_singleton_method(:thread) do
  Thread.current
end
pipeline.define_singleton_method(:finished_execution?) do
  false
end
pipeline.define_singleton_method(:reporter) do
  reporter
end
pipeline.define_singleton_method(:worker_threads_draining?) do
  %{value_placeholder}
end
pipeline.define_singleton_method(:pipeline_id) do
  "fake_test_pipeline"
end
pipeline
