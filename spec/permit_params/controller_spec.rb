# frozen_string_literal: true

RSpec.describe PermitParams::Controller do
  subject(:controller) { controller_class.new(action, request_params) }

  let(:action) { :show }
  let(:request_params) { {} }
  let(:controller_class) { Class.new(FakeController) }

  def filtered_params
    controller.send(:params)
  end

  describe "permit schema" do
    let(:controller_class) do
      Class.new(FakeController) do
        permit_params(:show, { permit: [:id, { hero: {} }] })
      end
    end
    let(:request_params) do
      { id: "1", evil: "x", hero: { name: "A", secret: "s" } }
    end

    it "keeps the permitted top-level keys" do
      expect(filtered_params.keys).to contain_exactly("id", "hero")
    end

    it "drops unpermitted top-level keys" do
      expect(filtered_params.key?("evil")).to be(false)
    end

    it "permits every key of a hash declared with an empty hash" do
      expect(filtered_params["hero"].keys).to contain_exactly("name", "secret")
    end
  end

  describe "deep filtering with a nested array" do
    let(:controller_class) do
      Class.new(FakeController) do
        permit_params(:show, { permit: [:id, { hero: [:name] }] })
      end
    end
    let(:request_params) { { id: "1", hero: { name: "A", secret: "s" } } }

    it "keeps only the listed nested keys" do
      expect(filtered_params["hero"].keys).to contain_exactly("name")
    end
  end

  describe "array shorthand" do
    let(:controller_class) do
      Class.new(FakeController) do
        permit_params(:index, [:page, :per_page])
      end
    end
    let(:action) { :index }
    let(:request_params) { { page: "1", per_page: "10", evil: "x" } }

    it "treats a bare array as a permit list" do
      expect(filtered_params.keys).to contain_exactly("page", "per_page")
    end
  end

  describe "required + permit schema" do
    let(:controller_class) do
      Class.new(FakeController) do
        permit_params(:create, required: :hero, permit: [:name, :rank])
      end
    end
    let(:action) { :create }

    context "when the required key is present" do
      let(:request_params) { { hero: { name: "A", rank: "S", evil: "x" } } }

      it "unwraps the required key and permits its nested attributes" do
        expect(filtered_params.keys).to contain_exactly("name", "rank")
      end
    end

    context "when the required key is missing" do
      let(:request_params) { { name: "A" } }

      it "raises ActionController::ParameterMissing" do
        expect { filtered_params }.to raise_error(ActionController::ParameterMissing)
      end
    end
  end

  describe "expect schema" do
    let(:controller_class) do
      Class.new(FakeController) do
        permit_params(:update, expect: { hero: [:id, :name, :rank] })
      end
    end
    let(:action) { :update }

    # +expect+ is only available on Rails >= 8.0, so the same schema is
    # exercised differently depending on the installed Action Pack version.
    if ActionController::Parameters.method_defined?(:expect)
      context "when the expected params are present" do
        let(:request_params) { { hero: { id: "1", name: "A", rank: "S", evil: "x" } } }

        it "returns the expected nested keys unwrapped" do
          expect(filtered_params.keys).to contain_exactly("id", "name", "rank")
        end
      end

      context "when the expected params are missing" do
        let(:request_params) { {} }

        it "raises ActionController::ParameterMissing" do
          expect { filtered_params }.to raise_error(ActionController::ParameterMissing)
        end
      end
    else
      it "raises PermitParams::Error on Rails < 8.0" do
        expect { filtered_params }.to raise_error(PermitParams::Error, /Rails >= 8\.0/)
      end
    end
  end

  describe "when the action has no schema" do
    let(:request_params) { { anything: "goes" } }

    it "returns the framework default params untouched" do
      expect(filtered_params).to be(controller.instance_variable_get(:@request_params))
    end
  end

  describe "schema isolation between controllers" do
    it "does not share schemas across controllers" do
      first = Class.new(FakeController) { permit_params(:show, permit: [:a]) }
      second = Class.new(FakeController) { permit_params(:show, permit: [:b]) }

      expect(first.param_schemas[:show]).to eq(permit: [:a])
      expect(second.param_schemas[:show]).to eq(permit: [:b])
    end

    it "does not mutate the parent class schema" do
      Class.new(FakeController) { permit_params(:show, permit: [:a]) }

      expect(FakeController.param_schemas).to eq({})
    end
  end

  describe "invalid schema" do
    it "raises at declaration time" do
      expect do
        Class.new(FakeController) { permit_params(:show, { foo: :bar }) }
      end.to raise_error(PermitParams::InvalidSchemaError)
    end

    it "raises when the schema is missing" do
      expect do
        Class.new(FakeController) { permit_params(:show) }
      end.to raise_error(ArgumentError)
    end
  end
end
