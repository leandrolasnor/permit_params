# frozen_string_literal: true

require "rails/generators"
require "generators/permit_params/install/install_generator"
require "stringio"
require "tmpdir"

RSpec.describe PermitParams::Generators::InstallGenerator do
  around do |example|
    Dir.mktmpdir("permit_params") do |destination|
      @destination = destination
      example.run
    end
  end

  def run_generator
    original_stdout = $stdout
    $stdout = StringIO.new
    described_class.start([], destination_root: @destination)
  ensure
    $stdout = original_stdout
  end

  def initializer_path
    File.join(@destination, "config/initializers/permit_params.rb")
  end

  it "creates config/initializers/permit_params.rb" do
    run_generator

    expect(File).to exist(initializer_path)
  end

  it "writes a PermitParams.configure block" do
    run_generator

    expect(File.read(initializer_path)).to include("PermitParams.configure do |config|")
  end

  it "documents both configuration options as comments" do
    run_generator

    content = File.read(initializer_path)

    expect(content).to include("# config.default_schema =")
    expect(content).to include("# config.raise_on_missing_schema =")
  end
end
