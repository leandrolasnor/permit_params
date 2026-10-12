# frozen_string_literal: true

module PermitParams
  # Wires PermitParams::Controller into every controller as soon as
  # ActionController is loaded, so installing the gem is enough to get the
  # +permit_params+ DSL everywhere.
  class Railtie < ::Rails::Railtie
    initializer "permit_params.include_controller" do
      # ActionController::Base and ActionController::API both run
      # :action_controller in Rails 8. The other two hooks are kept so the gem
      # also works on older versions; including the same module twice is a no-op.
      ActiveSupport.on_load(:action_controller) do
        include PermitParams::Controller
      end

      ActiveSupport.on_load(:action_controller_base) do
        include PermitParams::Controller
      end

      ActiveSupport.on_load(:action_controller_api) do
        include PermitParams::Controller
      end
    end
  end
end
