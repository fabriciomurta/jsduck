require "mini_parser"

describe JsDuck::Aggregator do
  def parse(string)
    Helper::MiniParser.parse(string, {:enums => true})
  end

  shared_examples_for "enum" do
    it "creates class" do
      expect(doc[:tagname]).to eq(:class)
    end
    it "sets :enum field" do
      expect(doc[:enum]).not_to eq(nil)
    end
    it "detects name" do
      expect(doc[:name]).to eq("My.enumeration.Type")
    end
    it "detects type" do
      expect(doc[:enum][:type]).to eq("String")
    end
    it "detects no extends" do
      expect(doc[:extends]).to eq(nil)
    end
    it "detects docs" do
      expect(doc[:doc]).to eq("Some documentation.")
    end

    it "detects two members" do
      expect(doc[:members].length).to eq(2)
    end

    describe "in first member" do
      let(:prop) { doc[:members][0] }
      it "detects name" do
        expect(prop[:name]).to eq('foo')
      end
      it "detects type" do
        expect(prop[:type]).to eq('String')
      end
      it "detects default value" do
        expect(prop[:default]).to eq("'a'")
      end
    end
  end

  shared_examples_for "doc_enum" do
    it "detects enum as only for documentation purposes" do
      expect(doc[:enum][:doc_only]).to eq(true)
    end
  end

  shared_examples_for "non_doc_enum" do
    it "doesn't detect an enum for doc purposes only" do
      expect(doc[:enum][:doc_only]).not_to eq(true)
    end
  end

  describe "explicit enum" do
    let(:doc) do
      parse(<<-EOS)["My.enumeration.Type"]
        /**
         * @enum {String} My.enumeration.Type
         * Some documentation.
         */
            /** @property {String} [foo='a'] */
            /** @property {String} [bar='b'] */
      EOS
    end

    it_should_behave_like "enum"
    it_should_behave_like "non_doc_enum"
  end

  describe "implicitly named enum" do
    let(:doc) do
      parse(<<-EOS)["My.enumeration.Type"]
        /**
         * @enum {String}
         * Some documentation.
         */
        My.enumeration.Type = {
            /** First value docs */
            foo: 'a',
            /** Second value docs */
            bar: 'b'
        };
      EOS
    end

    it_should_behave_like "enum"
    it_should_behave_like "non_doc_enum"
  end

  describe "enum with implicit values" do
    let(:doc) do
      parse(<<-EOS)["My.enumeration.Type"]
        /**
         * @enum {String}
         * Some documentation.
         */
        My.enumeration.Type = {
            foo: 'a',
            bar: 'b'
        };
      EOS
    end

    it_should_behave_like "enum"
  end

  describe "enum without a type" do
    let(:doc) do
      parse(<<-EOS)["My.enumeration.Type"]
        /**
         * @enum
         * Some documentation.
         */
        My.enumeration.Type = {
            foo: 'a',
            bar: 'b'
        };
      EOS
    end

    it "infers type from code" do
      expect(doc[:enum][:type]).to eq('String')
    end
  end

  describe "enum without a type and no type in code" do
    let(:doc) do
      parse(<<-EOS)["My.enumeration.Type"]
        /**
         * @enum
         * Some documentation.
         */
        My.enumeration.Type = {};
      EOS
    end

    it "defaults to Object type" do
      expect(doc[:enum][:type]).to eq('Object')
    end
  end

  describe "enum with multiple types in code" do
    let(:doc) do
      parse(<<-EOS)["My.enumeration.Type"]
        /**
         * @enum
         * Some documentation.
         */
        My.enumeration.Type = {
            foo: 15,
            bar: 'hello',
            baz: 8
        };
      EOS
    end

    it "defaults to auto-generated type union" do
      expect(doc[:enum][:type]).to eq('Number/String')
    end
  end

  describe "enum of two properties" do
    let(:doc) do
      parse(<<-EOS)["My.enumeration.Type"]
        /** @enum */
        My.enumeration.Type = {
            foo: "hello",
            /** @inheritdoc */
            bar: 8
        };
      EOS
    end

    it "gets stripped from :inheritdoc tag in auto-detected member" do
      expect(doc[:members][0][:inheritdoc]).to eq(nil)
    end

    it "keeps the explicit :inheritdoc tag in doc-commented member" do
      expect(doc[:members][1][:inheritdoc]).not_to eq(nil)
    end
  end

  describe "enum with array value" do
    let(:doc) do
      parse(<<-EOS)["My.enumeration.Type"]
        /** @enum */
        My.enumeration.Type = [
            "foo",
            "bar"
        ];
      EOS
    end

    let(:members) { doc[:members] }

    it_should_behave_like "doc_enum"

    it "detects all members" do
      expect(members.length).to eq(2)
    end

    it "detects as property" do
      expect(members[0][:tagname]).to eq(:property)
    end

    it "gets name" do
      expect(members[0][:name]).to eq('foo')
    end

    it "gets default value" do
      expect(members[0][:default]).to eq('"foo"')
    end

    it "gets type" do
      expect(members[0][:type]).to eq('String')
    end
  end

  describe "enum with documented array values" do
    let(:doc) do
      parse(<<-EOS)["My.enumeration.Smartness"]
        /** @enum */
        My.enumeration.Smartness = [
            // A wise choice.
            "wise",
            // A foolish decision.
            "fool"
        ];
      EOS
    end

    let(:members) { doc[:members] }

    it_should_behave_like "doc_enum"

    it "detects docs of first member" do
      expect(members[0][:doc]).to eq('A wise choice.')
    end

    it "detects docs of second member" do
      expect(members[1][:doc]).to eq('A foolish decision.')
    end
  end

  describe "enum of widget.*" do
    let(:doc) do
      parse(<<-EOS)["xtype"]
        /** @enum [xtype=widget.*] */
        /** @class Form @alias widget.form */
        /** @class Button @alias widget.button */
        /** @class TextArea @alias widget.textarea @private */
      EOS
    end

    it "detects enum type as String" do
      expect(doc[:enum][:type]).to eq("String")
    end

    it_should_behave_like "doc_enum"

    let(:members) { doc[:members] }

    it "gathers all 3 widget.* aliases" do
      expect(members.length).to eq(3)
    end

    it "lists all widget.* names" do
      expect(Set.new(members.map {|p| p[:name] })).to eq(Set.new(["form", "button", "textarea"]))
    end

    it "auto-generates property default values" do
      expect(Set.new(members.map {|p| p[:default] })).to eq(Set.new(["'form'", "'button'", "'textarea'"]))
    end

    it "sets property type to String" do
      expect(members[0][:type]).to eq("String")
    end

    it "sets enum value from private class as private" do
      expect(members.find_all {|p| p[:private] }.map {|p| p[:name] }).to eq(["textarea"])
    end

    it "lists class name in enum property docs" do
      expect(members.find_all {|p| p[:name] == 'form' }[0][:doc]).to eq("Alias for {@link Form}.")
    end
  end

  describe "enum with events as members" do
    let(:doc) do
      parse(<<-EOS)["My.enumeration.Type"]
        /**
         * @enum My.enumeration.Type
         */
            /** @event foo */
            /** @event bar */
            /** @property zap */
      EOS
    end

    it "throws away all events, keeping only properties" do
      expect(doc[:members].length).to eq(1)
    end
  end

end
