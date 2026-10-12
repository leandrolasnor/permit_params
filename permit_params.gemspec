# frozen_string_literal: true

require_relative "lib/permit_params/version"

Gem::Specification.new do |spec|
  spec.name = "permit_params"
  spec.version = PermitParams::VERSION
  spec.authors = ["Lasnor"]
  spec.email = ["leandrolsnr@gmail.com"]

  spec.summary = "Declarative, per-action strong parameter schemas for Rails controllers."
  spec.description = <<~DESC
    permit_params adds a `permit_params` class macro that lets you declare the
    expected parameters for each controller action and applies them automatically.
    It supports `permit`, `required` + `permit`, and the Rails 8 `expect` API, and
    is included into every ActionController::Base/ActionController::API by a Railtie.
  DESC
  spec.homepage = "https://github.com/leandrolasnor/permit_params"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 3.1"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = spec.homepage
  spec.metadata["changelog_uri"] = "#{spec.homepage}/blob/main/CHANGELOG.md"
  spec.metadata["rubygems_mfa_required"] = "true"

  spec.files = Dir[
    "lib/**/*",
    "README.md",
    "CHANGELOG.md",
    "LICENSE.txt"
  ].select { |file| File.file?(file) }
  spec.require_paths = ["lib"]

  spec.add_dependency "actionpack", ">= 7.0", "< 9.0"
  spec.add_dependency "activesupport", ">= 7.0", "< 9.0"
end
