require "jsduck/relations"
require "jsduck/type_parser"
require "jsduck/format/doc"
require "jsduck/class"
require "ostruct"

describe JsDuck::TypeParser do

  def parse(str)
    relations = JsDuck::Relations.new([], [
      "String",
      "Number",
      "RegExp",
      "Array",
      "Ext.form.Panel",
      "Ext.Element",
      "Ext.fx2.Anim",
    ])
    formatter = OpenStruct.new(:relations => relations)
    JsDuck::TypeParser.new(formatter).parse(str)
  end

  it "matches single-quoted string literal" do
    expect(parse("'foo'")).to eq(true)
  end

  it "matches double-quoted string literal" do
    expect(parse('"blah blah"')).to eq(true)
  end

  it "matches string literal with escape quote inside" do
    expect(parse('"blah \\"blah"')).to eq(true)
  end

  it "matches integer number literal" do
    expect(parse('42')).to eq(true)
  end

  it "matches negative number literal" do
    expect(parse('-6')).to eq(true)
  end

  it "matches float number literal" do
    expect(parse('3.14')).to eq(true)
  end

  it "matches simple type" do
    expect(parse("String")).to eq(true)
  end

  it "matches namespaced type" do
    expect(parse("Ext.form.Panel")).to eq(true)
  end

  it "matches type name containing number" do
    expect(parse("Ext.fx2.Anim")).to eq(true)
  end

  it "matches array of simple types" do
    expect(parse("Number[]")).to eq(true)
  end

  it "matches array of namespaced types" do
    expect(parse("Ext.form.Panel[]")).to eq(true)
  end

  it "matches 2D array" do
    expect(parse("String[][]")).to eq(true)
  end

  it "matches 3D array" do
    expect(parse("String[][][]")).to eq(true)
  end

  describe "matches alteration of" do
    it "simple types" do
      expect(parse("Number/String")).to eq(true)
    end

    it "literals" do
      expect(parse("'foo'/'bar'/32/4")).to eq(true)
    end

    it "simple- and namespaced- and array types" do
      expect(parse("Number/Ext.form.Panel/String[]/RegExp/Ext.Element")).to eq(true)
    end
  end

  describe "matches varargs of" do
    it "simple type" do
      expect(parse("Number...")).to eq(true)
    end

    it "namespaced type" do
      expect(parse("Ext.form.Panel...")).to eq(true)
    end

    it "array of simple types" do
      expect(parse("String[]...")).to eq(true)
    end

    it "array of namespaced types" do
      expect(parse("Ext.form.Panel[]...")).to eq(true)
    end

    it "complex alteration" do
      expect(parse("Ext.form.Panel[]/Number/Ext.Element...")).to eq(true)
    end

    it "in the middle" do
      expect(parse("Number.../String")).to eq(true)
    end
  end

  describe "doesn't match" do
    it "empty string" do
      expect(parse("")).to eq(false)
    end

    it "unknown type name" do
      expect(parse("Blah")).to eq(false)
    end

    it "type ending with dot" do
      expect(parse("Ext.")).to eq(false)
    end

    it "type beginning with dot" do
      expect(parse(".Ext")).to eq(false)
    end

    it "the [old] array notation" do
      expect(parse("[Number]")).to eq(false)
    end

    it "/ at the beginning" do
      expect(parse("/Number")).to eq(false)
    end

    it "/ at the end" do
      expect(parse("Number/")).to eq(false)
    end
  end

  # Type expressions supported by closure compiler:
  # https://developers.google.com/closure/compiler/docs/js-for-compiler#types
  describe "supporting closure compiler" do

    it "matches the ALL type" do
      expect(parse("*")).to eq(true)
    end

    describe "varargs" do
      it "matches the notation at the beginning" do
        expect(parse("...String")).to eq(true)
      end

      it "doesn't accept notation without a type name" do
        expect(parse("...")).to eq(false)
      end

      it "doesn't accept both notations at the same time" do
        expect(parse("...*...")).to eq(false)
      end
    end

    it "matches the nullable notation" do
      expect(parse("?String")).to eq(true)
    end

    it "matches the non-nullable notation" do
      expect(parse("!String")).to eq(true)
    end

    it "doesn't accept both nullable and non-nullable at the same time" do
      expect(parse("?!String")).to eq(false)
      expect(parse("!?String")).to eq(false)
    end

    describe "alteration" do
      it "matches pipes" do
        expect(parse("String|Number|RegExp")).to eq(true)
      end

      it "matches with extra spacing" do
        expect(parse(" String | Number ")).to eq(true)
      end
    end

    describe "union" do
      it "matches one simple type" do
        expect(parse("(String)")).to eq(true)
      end

      it "matches two simple types" do
        expect(parse("(String|Number)")).to eq(true)
      end

      it "matches in varargs context" do
        expect(parse("...(String|Number)")).to eq(true)
      end

      it "natches with nested union" do
        expect(parse("(String|(Number|RegExp))")).to eq(true)
      end

      it "matches with extra spacing" do
        expect(parse("( String | Number )")).to eq(true)
      end
    end

    # This is handled inside DocParser, when it's detected over there
    # the "=" is removed from the end of type definition, so it should
    # never reach TypeParser if there is just one "=" at the end of
    # type definition.
    #
    # We do support the optional notation inside function type
    # parameter lists (see below).
    it "doesn't accept optional parameter notation" do
      expect(parse("String=")).to eq(false)
    end

    describe "type arguments" do
      it "matches single" do
        expect(parse("Array.<Number>")).to eq(true)
      end

      it "matches multiple" do
        expect(parse("Ext.Element.<String,Number>")).to eq(true)
      end

      it "matches with extra spacing" do
        expect(parse("Ext.Element.< String , Number >")).to eq(true)
      end

      it "matches with nested type arguments" do
        expect(parse("Array.<Array.<String>|Array.<Number>>")).to eq(true)
      end

      it "doesn't accept on type union" do
        expect(parse("(Array|RegExp).<String>")).to eq(false)
      end

      it "doesn't accept empty" do
        expect(parse("Array.<>")).to eq(false)
      end
    end

    describe "function type" do
      it "matches empty" do
        expect(parse("function()")).to eq(true)
      end

      it "matches arguments" do
        expect(parse("function(String,Number)")).to eq(true)
      end

      it "matches return type" do
        expect(parse("function():Number")).to eq(true)
      end

      it "matches with varargs" do
        expect(parse("function(...Number)")).to eq(true)
      end

      # For some reason Google Closure Compiler requires varargs type
      # in function argument context to be wrapped inside [] brackets.
      it "matches ...[] varargs syntax" do
        expect(parse("function(...[String])")).to eq(true)
      end

      it "matches nullable/non-nullable arguments" do
        expect(parse("function(!String, ?Number)")).to eq(true)
      end

      it "matches optional argument" do
        expect(parse("function(Number=)")).to eq(true)
      end

      it "matches this: argument" do
        expect(parse("function(this:Array, Number)")).to eq(true)
      end

      it "matches new: argument" do
        expect(parse("function(new:Array)")).to eq(true)
      end

      it "matches this: argument + ws" do
        expect(parse("function(this : Array, Number)")).to eq(true)
      end

      it "matches new: argument + ws" do
        expect(parse("function(new : Array)")).to eq(true)
      end

      it "matches with extra whitespace" do
        expect(parse("function(  ) : Array")).to eq(true)
      end
    end

    describe "record type" do
      it "matches list of properties" do
        expect(parse("{foo, bar, baz}")).to eq(true)
      end

      it "matches properties with types" do
        expect(parse("{foo: String, bar: Number}")).to eq(true)
      end

      it "matches property with complex type" do
        expect(parse("{foo: (String|Array.<String>)}")).to eq(true)
      end

      it "matches nested record type" do
        expect(parse("{foo: {bar}}")).to eq(true)
      end
    end

    it "always matches primitive types" do
      expect(parse("boolean")).to eq(true)
      expect(parse("number")).to eq(true)
      expect(parse("string")).to eq(true)
      expect(parse("null")).to eq(true)
      expect(parse("undefined")).to eq(true)
      expect(parse("void")).to eq(true)
    end

    it "links primitive types to classes" do
      relations = JsDuck::Relations.new([JsDuck::Class.new({:name => "String"})])
      doc_formatter = JsDuck::Format::Doc.new(relations)
      p = JsDuck::TypeParser.new(doc_formatter)
      p.parse("string")
      expect(p.out).to eq('<a href="String">string</a>')
    end

    def parse_to_output(input)
      relations = JsDuck::Relations.new([])
      formatter = OpenStruct.new(:relations => relations)
      p = JsDuck::TypeParser.new(formatter)
      p.parse(input)
      return p.out
    end

    it "preserves whitespace in output" do
      expect(parse_to_output("( string | number )")).to eq("( string | number )")
    end

    it "converts < and > to HTML entities in output" do
      expect(parse_to_output("number.<string, *>")).to eq("number.&lt;string, *&gt;")
    end

    it "preserves function notation in output" do
      input = 'function(this:string, ?number=, !number, ...[number]): boolean'
      expect(parse_to_output(input)).to eq(input)
    end

    it "preserves object literal notation in output" do
      input = '{myNum: number, myObject}'
      expect(parse_to_output(input)).to eq(input)
    end

  end

end
