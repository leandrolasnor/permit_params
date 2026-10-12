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
  end
end
