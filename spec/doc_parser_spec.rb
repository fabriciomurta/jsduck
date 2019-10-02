require "jsduck/doc/parser"

describe JsDuck::Doc::Parser do

  def parse_single(doc)
    return JsDuck::Doc::Parser.new.parse(doc)
  end

  describe "simple method doc-comment" do
    before do
      @doc = parse_single(<<-EOS.strip)
         * @method foo
         * Some docs.
         * @param {Number} x doc for x
         * @return {String} resulting value
      EOS
    end

    it "produces 3 @tags" do
      expect(@doc.length).to eq(4)
    end

    describe "special :doc tag" do
      before do
        @tag = @doc[0]
      end
      it "gets special :doc tagname" do
        expect(@tag[:tagname]).to eq(:doc)
      end
      it "detects doc" do
        expect(@tag[:doc]).to eq("Some docs.")
      end
    end

    describe "@method" do
      before do
        @tag = @doc[1]
      end
      it "detects tagname" do
        expect(@tag[:tagname]).to eq(:method)
      end
      it "detects name" do
        expect(@tag[:name]).to eq("foo")
      end
      it "doesn't detects doc" do
        expect(@tag[:doc]).to eq(nil)
      end
    end

    describe "@param" do
      before do
        @tag = @doc[2]
      end
      it "detects tagname" do
        expect(@tag[:tagname]).to eq(:params)
      end
      it "detects name" do
        expect(@tag[:name]).to eq("x")
      end
      it "detects type" do
        expect(@tag[:type]).to eq("Number")
      end
      it "detects doc" do
        expect(@tag[:doc]).to eq("doc for x")
      end
    end

    describe "@return" do
      before do
        @tag = @doc[3]
      end
      it "detects tagname" do
        expect(@tag[:tagname]).to eq(:return)
      end
      it "detects type" do
        expect(@tag[:type]).to eq("String")
      end
      it "detects doc" do
        expect(@tag[:doc]).to eq("resulting value")
      end
    end
  end

  describe "@type without curlies" do
    before do
      @tag = parse_single(<<-EOS.strip)[1]
         * @type Boolean|String
      EOS
    end
    it "detects tagname" do
      expect(@tag[:tagname]).to eq(:type)
    end
    it "detects tagname" do
      expect(@tag[:type]).to eq("Boolean|String")
    end
  end

  describe "single-line doc-comment" do
    before do
      @tag = parse_single("@event blah")[1]
    end
    it "detects tagname" do
      expect(@tag[:tagname]).to eq(:event)
    end
    it "detects name" do
      expect(@tag[:name]).to eq("blah")
    end
  end

  describe "doc-comment without *-s on left side" do
    before do
      @tags = parse_single("
        @event blah
        Some comment.
        More text.

            code sample
        ")
    end
    it "detects the @event tag" do
      expect(@tags[1][:tagname]).to eq(:event)
    end
    it "trims whitespace at beginning of lines up to first line" do
      expect(@tags[0][:doc]).to eq("Some comment.\nMore text.\n\n    code sample")
    end
  end

  describe "type definition with nested {braces}" do
    before do
      @tag = parse_single(<<-EOS.strip)[1]
         * @param {{foo:{bar:Number}}} x
      EOS
    end
    it "is parsed ensuring balanced braces" do
      expect(@tag[:type]).to eq("{foo:{bar:Number}}")
    end
  end

  describe "e-mail address containing a valid @tag" do
    before do
      @tag = parse_single(<<-EOS.strip)[0]
         * john@method.com
      EOS
    end
    it "is treated as plain text" do
      expect(@tag[:doc]).to eq("john@method.com")
    end
  end

  describe "{@inline} tag" do
    before do
      @tag = parse_single(<<-EOS.strip)[0]
         * {@inline Some#method}
      EOS
    end
    it "is treated as plain text, to be processed later" do
      expect(@tag[:doc]).to eq("{@inline Some#method}")
    end
  end

  describe "@example tag" do
    before do
      @tag = parse_single(<<-EOS.strip)[0]
         * Code:
         *
         *     @example blah
      EOS
    end
    it "is treated as plain text, to be processed later" do
      expect(@tag[:doc]).to eq("Code:\n\n    @example blah")
    end
  end

  describe "@tag indented by 4+ spaces" do
    before do
      @tag = parse_single(<<-EOS.strip)[0]
         * Code example:
         *
         *     @method
      EOS
    end
    it "is treated as plain text within code example" do
      expect(@tag[:doc]).to eq("Code example:\n\n    @method")
    end
  end

  describe "@tag indented by 4+ spaces and preceded by additional code" do
    before do
      @tag = parse_single(<<-EOS.strip)[0]
         * Code example:
         *
         *     if @method then
      EOS
    end
    it "is treated as plain text within code example" do
      expect(@tag[:doc]).to eq("Code example:\n\n    if @method then")
    end
  end

  describe "@tag simply separated by 4+ spaces" do
    before do
      @tag = parse_single(<<-EOS.strip)[1]
         * Foo:    @method
      EOS
    end
    it "is parsed as normal tag" do
      expect(@tag[:tagname]).to eq(:method)
    end
  end

  describe "indented code on previous line" do
    before do
      @params = parse_single(<<-EOS.strip).find_all {|t| t[:tagname] == :params }
         * @param x
         *     Foo
         *     Bar
         * @param y
      EOS
    end
    it "doesn't cause the tag to be skipped" do
      expect(@params.length).to eq(2)
    end
  end

end
