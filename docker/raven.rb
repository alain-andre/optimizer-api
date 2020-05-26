# Configure Raven to be able to use it in root server process and workers process

require 'raven'

Raven.configure { |config|
  config.dsn = 'http://localhost/'
}
