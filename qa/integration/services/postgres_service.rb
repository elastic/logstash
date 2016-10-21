class PostgresService < Service
  def initialize(settings)
    super("postgres", settings)
  end
end