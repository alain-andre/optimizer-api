# Configure Raven to be able to use it in root server process and workers process

require 'raven'

Raven.configure { |config|
  config.dsn = 'http://7ac15ddde8a34c629893a04779f10640:f0c08ce7a3d94f05acb6d85f407be6e2@sentry.mapotempo.com/15'
}
