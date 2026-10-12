# frozen_string_literal: true

RSpec.describe PermitParams::Configuration do
  describe "defaults" do
    it "has no default schema" do
      expect(PermitParams.configuration.default_schema).to be_nil
    end

    it "does not raise on missing schemas" do
      expect(PermitParams.configuration.raise_on_missing_schema).to be(false)
    end
  end

  describe ".configure" do
    it "yields the singleton configuration" do
      configured = PermitParams.configure do |config|
        config.raise_on_missing_schema = true
      end

      expect(configured.raise_on_missing_schema).to be(true)
      expect(PermitParams.configuration.raise_on_missing_schema).to be(true)
    end
  end

  describe "default_schema applied to actions without their own schema" do
    let(:controller) { Class.new(FakeController).new(:show, request_params) }
    let(:request_params) { { page: "2", evil: "x" } }

    before do
      PermitParams.configure { |config| config.default_schema = { permit: [:page] } }
    end

    it "uses the global schema as a fallback" do
      expect(controller.send(:params).keys).to contain_exactly("page")
    end
  end

  describe "default_schema as a bare Array (shorthand)" do
    let(:controller) { Class.new(FakeController).new(:show, { page: "2", evil: "x" }) }

    before do
      PermitParams.configure { |config| config.default_schema = [:page] }
    end

    it "normalizes the shorthand before applying it" do
      expect(controller.send(:params).keys).to contain_exactly("page")
    end
  end

  describe "default_schema with a required key" do
    let(:controller) { Class.new(FakeController).new(:create, { hero: { name: "A", evil: "x" } }) }

    before do
      PermitParams.configure { |config| config.default_schema = { required: :hero, permit: [:name] } }
    end

    it "unwraps the required key and permits its nested attributes" do
      expect(controller.send(:params).keys).to contain_exactly("name")
    end
  end

  describe "own schema takes precedence over default_schema" do
    let(:controller_class) { Class.new(FakeController) { permit_params(:show, permit: [:id]) } }
    let(:controller) { controller_class.new(:show, { id: "1", page: "2", evil: "x" }) }

    before do
      PermitParams.configure { |config| config.default_schema = { permit: [:page] } }
    end

    it "applies the action schema instead of the default one" do
      expect(controller.send(:params).keys).to contain_exactly("id")
    end
  end

  describe "raise_on_missing_schema" do
    let(:controller) { Class.new(FakeController).new(:show, {}) }

    before do
      PermitParams.configure { |config| config.raise_on_missing_schema = true }
    end

    it "raises for actions without a schema" do
      expect { controller.send(:params) }.to raise_error(PermitParams::MissingSchemaError)
    end
  end

  describe ".reset_configuration!" do
    it "restores the defaults" do
      PermitParams.configure { |config| config.raise_on_missing_schema = true }
      PermitParams.reset_configuration!

      expect(PermitParams.configuration.raise_on_missing_schema).to be(false)
    end

    it "clears the default schema" do
      PermitParams.configure { |config| config.default_schema = { permit: [:id] } }
      PermitParams.reset_configuration!

      expect(PermitParams.configuration.default_schema).to be_nil
    end
  end
end
