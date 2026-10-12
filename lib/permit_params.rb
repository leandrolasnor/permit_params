# frozen_string_literal: true

require "active_support"
require "active_support/core_ext/class/attribute"
require "active_support/concern"

require "permit_params/version"
require "permit_params/configuration"
require "permit_params/controller"
require "permit_params/railtie" if defined?(::Rails::Railtie)

# Declarative, per-action strong parameter schemas for Rails controllers.
#
#   class HeroesController < ApplicationController
#     permit_params :show,   { permit: [:id, { hero: {} }] }
#     permit_params :create, required: :hero, permit: [:name, :rank, :lat, :lng]
#     permit_params :update, expect: { hero: [:id, :name, :rank, :lat, :lng] }
#   end
module PermitParams
  class Error < StandardError; end

  # Raised when a schema is neither an Array nor a Hash with one of
  # +:permit+, +:required+ or +:expect+.
  class InvalidSchemaError < Error; end

  # Raised for actions without a schema when
  # +PermitParams.configuration.raise_on_missing_schema+ is enabled.
  class MissingSchemaError < Error; end

  class << self
    # Current global configuration.
    def configuration
      @configuration ||= Configuration.new
    end

    # Yields the configuration for modification and returns it.
    #
    #   PermitParams.configure do |config|
    #     config.default_schema = { permit: [:page, :per_page] }
    #   end
    def configure
      yield configuration if block_given?
      configuration
    end

    # Restores the default configuration. Mainly useful in tests.
    def reset_configuration!
      @configuration = nil
    end

    # Applies +schema+ to an ActionController::Parameters instance and returns
    # the filtered parameters.
    def apply(params, schema)
      schema = normalize_schema(schema)

      if schema.key?(:expect)
        expect_params(params, schema[:expect])
      elsif schema.key?(:required)
        params.required(schema[:required]).permit(*Array(schema[:permit]))
      else
        params.permit(*Array(schema[:permit]))
      end
    end

    # Validates a schema and normalizes the Array shorthand into a Hash.
    def normalize_schema(schema)
      return { permit: schema } if schema.is_a?(Array)

      unless schema.is_a?(Hash) && (schema.key?(:permit) || schema.key?(:required) || schema.key?(:expect))
        raise InvalidSchemaError,
              "schema must be an Array or a Hash with one of :permit, :required or :expect (got #{schema.inspect})"
      end

      schema
    end

    private

    def expect_params(params, filters)
      unless params.respond_to?(:expect)
        raise Error, "`expect:` schemas require ActionController::Parameters#expect (Rails >= 8.0)"
      end

      params.expect(filters)
    end
  end
end
