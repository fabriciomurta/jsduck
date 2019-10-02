require "mini_parser"

describe JsDuck::Aggregator do
  def parse(string)
    Helper::MiniParser.parse(string, {:inherit_doc => true})
  end

  describe "Inheriting from parent with @localdoc" do
    let(:cls) do
      @docs = parse(<<-EOF)
        /**
         * @class Parent
         * Parent docs.
         * @localdoc Parent-specific docs.
         */

        /**
         * @class Child
         * @extend Parent
         * @inheritdoc
         */
      EOF

      @docs["Child"]
    end

    it "inherits :doc" do
      expect(cls[:doc]).to eq("Parent docs.")
    end

    it "doesn't inherit @localdoc" do
      expect(cls[:localdoc]).to eq(nil)
    end
  end

  describe "Inheriting while having @localdoc in both parent and child" do
    let(:cls) do
      @docs = parse(<<-EOF)
        /**
         * @class Parent
         * Parent docs.
         * @localdoc Parent-specific docs.
         */

        /**
         * @class Child
         * @extend Parent
         * @inheritdoc
         * @localdoc Child-specific docs.
         */
      EOF

      @docs["Child"]
    end

    it "inherits :doc" do
      expect(cls[:doc]).to eq("Parent docs.")
    end

    it "keeps local @localdoc" do
      expect(cls[:localdoc]).to eq("Child-specific docs.")
    end
  end

end
