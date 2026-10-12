# frozen_string_literal: true

# Minimal stand-in for a controller in the spec suite. The +params+ method
# lives on the base class so that PermitParams::Controller#params can call
# +super+ just like it does in a real controller.
class FakeBaseController
  attr_accessor :action_name

  def initialize(action_name, request_params)
    @action_name = action_name.to_s
    @request_params = ActionController::Parameters.new(request_params)
  end

  private

  def params
    @request_params
  end
end

class FakeController < FakeBaseController
  include PermitParams::Controller
end
