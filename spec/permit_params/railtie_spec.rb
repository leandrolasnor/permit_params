# frozen_string_literal: true

require "rails/railtie"
require "permit_params/railtie"

RSpec.describe PermitParams::Railtie do
  # Mirrors what Rails does at boot: run the initializer (which registers the
  # ActiveSupport load hooks), then fire a hook at the class being loaded.
  def run_initializer
    described_class.initializers.each { |initializer| initializer.block.call }
  end

  it "is a Rails::Railtie" do
    expect(described_class).to be < ::Rails::Railtie
  end

  it "registers the controller-including initializer" do
    expect(described_class.initializers.map(&:name))
      .to include("permit_params.include_controller")
  end

  %i[action_controller action_controller_base action_controller_api].each do |hook|
    it "includes PermitParams::Controller through the #{hook} hook" do
      run_initializer
      controller = Class.new

      ActiveSupport.run_load_hooks(hook, controller)

      expect(controller.include?(PermitParams::Controller)).to be(true)
    end
  end

  it "is idempotent when the same hook fires more than once" do
    run_initializer
    controller = Class.new

    2.times { ActiveSupport.run_load_hooks(:action_controller, controller) }

    expect(controller.include?(PermitParams::Controller)).to be(true)
  end
end
