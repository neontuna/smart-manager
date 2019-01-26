require_relative 'boot'

require 'rails/all'

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module SmartManager
  class Application < Rails::Application
    # Allows for using module namespacing, see app/services for example
    config.autoload_paths += %W(#{config.root}/app)
    
    config.application_name = Rails.application.class.parent_name
    config.active_job.queue_adapter = :sidekiq
    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 5.2

    # Settings in config/environments/* take precedence over those specified here.
    # Application configuration can go into files in config/initializers
    # -- all .rb files in that directory are automatically loaded after loading
    # the framework and any gems in your application.
  end
end
