# frozen_string_literal: true

require "active_support/all"
require "action_controller/metal/strong_parameters"
require "permit_params"

# Keep unpermitted parameter handling quiet while running the suite.
ActionController::Parameters.action_on_unpermitted_parameters = false

Dir[File.expand_path("support/**/*.rb", __dir__)].sort.each { |file| require file }

RSpec.configure do |config|
  config.disable_monkey_patching!
  config.order = :random
  Kernel.srand config.seed

  config.before { PermitParams.reset_configuration! }
end
