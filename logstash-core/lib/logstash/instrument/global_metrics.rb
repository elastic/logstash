class GlobalMetrics
  class Stats(metric)
    @metric = metric
  end

  def initialize(metric)
    @metric = metric

    @pipeline_reloads = metric.namespace([:stats, :pipelines])
  end


end