# frozen_string_literal: true

RSpec.describe PermitParams do
  def params(hash)
    ActionController::Parameters.new(hash)
  end

  describe ".normalize_schema" do
    it "wraps a bare Array as a permit list" do
      expect(described_class.normalize_schema([:a, :b])).to eq(permit: [:a, :b])
    end

    it "returns a Hash with :permit untouched" do
      schema = { permit: [:a] }

      expect(described_class.normalize_schema(schema)).to be(schema)
    end

    it "returns a Hash with :required untouched" do
      schema = { required: :hero, permit: [:a] }

      expect(described_class.normalize_schema(schema)).to be(schema)
    end

    it "returns a Hash with :expect untouched" do
      schema = { expect: { hero: [:a] } }

      expect(described_class.normalize_schema(schema)).to be(schema)
    end

    it "raises for a Hash without a known key" do
      expect { described_class.normalize_schema({ foo: :bar }) }
        .to raise_error(PermitParams::InvalidSchemaError)
    end

    it "raises for input that is neither an Array nor a Hash" do
      ["string", nil, 123].each do |bad|
        expect { described_class.normalize_schema(bad) }
          .to raise_error(PermitParams::InvalidSchemaError)
      end
    end
  end

  describe "error hierarchy" do
    it "nests the errors below PermitParams::Error < StandardError" do
      expect(PermitParams::InvalidSchemaError).to be < PermitParams::Error
      expect(PermitParams::MissingSchemaError).to be < PermitParams::Error
      expect(PermitParams::Error).to be < StandardError
    end
  end

  describe ".apply" do
    it "permits the listed top-level keys" do
      result = described_class.apply(params(id: "1", evil: "x"), permit: [:id])

      expect(result.keys).to contain_exactly("id")
    end

    it "accepts a bare Array as shorthand for permit" do
      result = described_class.apply(params(id: "1", evil: "x"), [:id])

      expect(result.keys).to contain_exactly("id")
    end

    it "permits every key of a nested hash declared with an empty hash" do
      result = described_class.apply(
        params(hero: { name: "A", secret: "s" }),
        permit: [{ hero: {} }]
      )

      expect(result["hero"].keys).to contain_exactly("name", "secret")
    end

    it "keeps only the listed nested keys" do
      result = described_class.apply(
        params(hero: { name: "A", secret: "s" }),
        permit: [{ hero: [:name] }]
      )

      expect(result["hero"].keys).to contain_exactly("name")
    end

    it "filters hashes nested three levels deep" do
      result = described_class.apply(
        params(hero: { pet: { name: "A", secret: "s" } }),
        permit: [{ hero: { pet: {} } }]
      )

      expect(result.dig("hero", "pet").keys).to contain_exactly("name", "secret")
    end

    it "filters every element of an array of nested hashes" do
      result = described_class.apply(
        params(heroes: [{ id: "1", evil: "x" }, { id: "2", evil: "y" }]),
        permit: [{ heroes: [:id] }]
      )

      expect(result["heroes"].map(&:keys)).to eq([["id"], ["id"]])
    end

    it "returns empty parameters when the permit list is empty" do
      result = described_class.apply(params(id: "1"), permit: [])

      expect(result.keys).to be_empty
    end

    it "keeps permitted keys whose value is nil or false" do
      result = described_class.apply(
        params(active: false, note: nil, evil: "x"),
        permit: [:active, :note]
      )

      expect(result.keys).to contain_exactly("active", "note")
      expect(result["active"]).to be(false)
      expect(result["note"]).to be_nil
    end

    it "returns empty parameters when the input is empty" do
      result = described_class.apply(params({}), permit: [:id])

      expect(result.keys).to be_empty
    end

    it "unwraps a required key and permits its nested attributes" do
      result = described_class.apply(
        params(hero: { name: "A", rank: "S", evil: "x" }),
        required: :hero, permit: [:name, :rank]
      )

      expect(result.keys).to contain_exactly("name", "rank")
    end

    it "returns empty parameters when a required key has no permit list" do
      result = described_class.apply(params(hero: { name: "A" }), required: :hero)

      expect(result.keys).to be_empty
    end

    it "raises ActionController::ParameterMissing when the required key is absent" do
      expect { described_class.apply(params(name: "A"), required: :hero, permit: [:name]) }
        .to raise_error(ActionController::ParameterMissing)
    end

    if ActionController::Parameters.method_defined?(:expect)
      it "resolves an :expect schema" do
        result = described_class.apply(
          params(hero: { id: "1", name: "A", evil: "x" }),
          expect: { hero: [:id, :name] }
        )

        expect(result.keys).to contain_exactly("id", "name")
      end

      it "prefers :expect over :required when both are present" do
        result = described_class.apply(
          params(hero: { id: "1", name: "A" }),
          expect: { hero: [:id] }, required: :hero, permit: [:id, :name]
        )

        expect(result.keys).to contain_exactly("id")
      end
    else
      it "raises PermitParams::Error for :expect on Rails < 8.0" do
        expect { described_class.apply(params(hero: { id: "1" }), expect: { hero: [:id] }) }
          .to raise_error(PermitParams::Error, /Rails >= 8\.0/)
      end
    end
  end
end
