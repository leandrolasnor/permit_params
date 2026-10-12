# frozen_string_literal: true

require "rails/generators"

module PermitParams
  module Generators
    # Creates +config/initializers/permit_params.rb+.
    #
    #   rails generate permit_params:install
    class InstallGenerator < ::Rails::Generators::Base
      source_root File.expand_path("templates", __dir__)

      desc "Creates a PermitParams initializer."

      def copy_initializer
        template "permit_params.rb", "config/initializers/permit_params.rb"
      end
    end
  end
end
