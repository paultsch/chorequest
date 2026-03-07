Sentry.init do |config|
  config.dsn = ENV['SENTRY_DSN']
  config.breadcrumbs_logger = [:active_support_logger, :http_logger]
  config.environment = Rails.env
  config.enabled_environments = %w[production staging]
  config.traces_sample_rate = 0.1
  config.send_default_pii = false

  config.excluded_exceptions += [
    'ActionController::RoutingError',
    'ActionController::UnknownFormat',
    'ActiveRecord::RecordNotFound',
    'Rack::QueryParser::InvalidParameterError'
  ]
end
