Merb.logger.info("Loaded RAKE Environment...")
Merb::Config.use { |c|
  c[:exception_details] = true
  c[:reload_classes]  = false
  c[:log_auto_flush ] = true

  c[:log_stream] = STDOUT
  c[:log_file]   = nil
  # Or redirect logging into a file:
  # c[:log_file]  = Merb.root / "log" / "development.log"
}
