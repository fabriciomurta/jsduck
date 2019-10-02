require 'jsduck/css/parser'

describe JsDuck::Css::Parser do

  def parse(string)
    JsDuck::Css::Parser.new(string).parse
  end

  describe "parsing empty string" do
    let(:docs) { parse("") }

    it "finds no documentation" do
      expect(docs.length).to eq(0)
    end
  end

  describe "parsing SCSS without doc-comments" do
    let(:docs) do
      parse(<<-EOCSS)
        // some comment
        a:href { color: green; }
        /* Shallalalaaa */
        $foo: 10em !default;
        /*! Goul */
        @mixin goul {
            font-weight: bold;
        }
      EOCSS
    end

    it "finds no documentation" do
      expect(docs.length).to eq(0)
    end
  end

  describe "parsing SCSS with lots of doc-comments" do
    let(:docs) do
      parse(<<-EOCSS)
        /** some comment */
        a:href { color: green; }
        /** Shallalalaaa */
        $foo: 10em !default;
        /** Goul */
        @mixin goul {
            /** Me too! */
            font-weight: bold;
        }
      EOCSS
    end

    it "finds them all" do
      expect(docs.length).to eq(4)
    end
  end

  describe "parsing SCSS variable" do
    let(:var) do
      parse(<<-EOCSS)[0]
        /** My variable */
        $foo: 10em !default;
      EOCSS
    end

    it "detects comment" do
      expect(var[:comment]).to eq(" My variable ")
    end

    it "detects line number" do
      expect(var[:linenr]).to eq(1)
    end

    it "detects :css_var type" do
      expect(var[:code][:tagname]).to eq(:css_var)
    end

    it "detects name" do
      expect(var[:code][:name]).to eq("$foo")
    end

    it "detects default value" do
      expect(var[:code][:default]).to eq("10em")
    end

    it "detects type" do
      expect(var[:code][:type]).to eq("number")
    end
  end

  describe "parsing SCSS mixin" do
    let(:var) do
      parse(<<-EOCSS)[0]
        /** My mixin */
        @mixin foo($alpha, $beta: 2px) {
            color: $alpha;
        }
      EOCSS
    end

    it "detects comment" do
      expect(var[:comment]).to eq(" My mixin ")
    end

    it "detects :css_mixin type" do
      expect(var[:code][:tagname]).to eq(:css_mixin)
    end

    it "detects name" do
      expect(var[:code][:name]).to eq("foo")
    end

    it "detects correct number of parameters" do
      expect(var[:code][:params].length).to eq(2)
    end

    it "detects name of first param" do
      expect(var[:code][:params][0][:name]).to eq("$alpha")
    end

    it "detects no default value for first param" do
      expect(var[:code][:params][0][:default]).to eq(nil)
    end

    it "detects name of second param" do
      expect(var[:code][:params][1][:name]).to eq("$beta")
    end

    it "detects default value for second param" do
      expect(var[:code][:params][1][:default]).to eq("2px")
    end

    it "detects type for second param" do
      expect(var[:code][:params][1][:type]).to eq("number")
    end
  end

  describe "parsing other SCSS code" do
    let(:var) do
      parse(<<-EOCSS)[0]
        /** My docs */
        .some-class a:href {
            color: #0f0;
        }
      EOCSS
    end

    it "detects comment" do
      expect(var[:comment]).to eq(" My docs ")
    end

    it "detects code as :property" do
      expect(var[:code][:tagname]).to eq(:property)
    end
  end

  describe "parsing doc-comment without any SCSS code afterwards" do
    let(:docs) do
      parse(<<-EOCSS)
        /** My docs */
      EOCSS
    end

    it "detects one docset" do
      expect(docs.length).to eq(1)
    end

    it "detects code as :property" do
      expect(docs[0][:code][:tagname]).to eq(:property)
    end
  end

  describe "parsing doc-comments without any SCSS code afterwards" do
    let(:docs) do
      parse(<<-EOCSS)
        /** My docs #1 */
        /** My docs #2 */
      EOCSS
    end

    it "detects two docsets" do
      expect(docs.length).to eq(2)
    end
  end

  describe "parsing SCSS variable followed by unknown function" do
    let(:var) do
      parse(<<-EOCSS)[0]
        /** My docs */
        $foo: myfunc(1, 2);
      EOCSS
    end

    it "detects the function call as default value" do
      expect(var[:code][:default]).to eq("myfunc(1, 2)")
    end
  end

end
