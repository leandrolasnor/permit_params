# frozen_string_literal: true

require "active_support/concern"
require "active_support/core_ext/class/attribute"

module PermitParams
  # Mixin that adds the +permit_params+ class macro and applies the schema
  # declared for the current action to +params+.
  #
  # It is included automatically into +ActionController::Base+ and
  # +ActionController::API+ by PermitParams::Railtie, so in a Rails app you
  # usually do not need to include it yourself.
  module Controller
    extend ActiveSupport::Concern

    included do
      class_attribute :param_schemas, instance_accessor: false, default: {}
    end

    class_methods do
      # Declares the parameter schema for +action+.
      #
      #   permit_params :show,   { permit: [:id, { hero: {} }] }
      #   permit_params :create, required: :hero, permit: [:name, :rank]
      #   permit_params :update, expect: { hero: [:id, :name, :rank] }
      #   permit_params :index,  [:page, :per_page] # shorthand for permit
      #
      # The schema is validated eagerly, so a malformed one fails while the
      # class is being (re)loaded instead of on the first request.
      def permit_params(action, schema = nil, **options)
        schema = options if schema.nil? && !options.empty?
        raise ArgumentError, "missing schema for action #{action.inspect}" if schema.nil?

        schema = PermitParams.normalize_schema(schema)
        self.param_schemas = param_schemas.merge(action.to_sym => schema)
      end

      # Schema for +action+, falling back to the global default when the action
      # does not declare one.
      def param_schema_for(action)
        param_schemas[action.to_sym] || PermitParams.configuration.default_schema
      end
    end

    private

    def params
      schema = self.class.param_schema_for(action_name)

      if schema.nil?
        if PermitParams.configuration.raise_on_missing_schema
          raise MissingSchemaError,
                "no parameter schema declared for action #{action_name.inspect} on #{self.class}"
        end

        return super
      end

      PermitParams.apply(super, schema)
    end
  end
end
