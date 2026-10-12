# frozen_string_literal: true

module PermitParams
  # Global configuration for the gem. Change it through +PermitParams.configure+,
  # usually in +config/initializers/permit_params.rb+:
  #
  #   PermitParams.configure do |config|
  #     config.default_schema = { permit: [:page, :per_page] }
  #     config.raise_on_missing_schema = true
  #   end
  class Configuration
    # Schema applied to actions that do not declare their own through
    # +permit_params+. Accepts the same shapes as +permit_params+ (a Hash like
    # <tt>{ permit: [...] }</tt>, <tt>{ required: :foo, permit: [...] }</tt> or
    # <tt>{ expect: { ... } }</tt>, or a bare Array as shorthand for +permit+).
    #
    # When +nil+ (the default) actions without a schema are left untouched and
    # receive the framework default +params+.
    attr_accessor :default_schema

    # When +true+, raises PermitParams::MissingSchemaError for any action that
    # has neither its own schema nor a +default_schema+. Useful to enforce that
    # every action is explicit. Defaults to +false+.
    attr_accessor :raise_on_missing_schema

    def initialize
      @default_schema = nil
      @raise_on_missing_schema = false
    end
  end
end
