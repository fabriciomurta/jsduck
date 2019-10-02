# encoding: ASCII
require "rkelly"
require "jsduck/js/rkelly_adapter"

describe JsDuck::Js::RKellyAdapter do
  def adapt(string)
    rkelly_ast = RKelly::Parser.new.parse(string)
    ast = JsDuck::Js::RKellyAdapter.new.adapt(rkelly_ast)
    return ast["body"][0]
  end

  def adapt_value(string)
    adapt(string)["expression"]["value"]
  end

  describe "values of numbers" do
    it "decimal" do
      expect(adapt_value("5")).to eq(5)
    end

    it "octal" do
      expect(adapt_value("015")).to eq(8 + 5)
    end

    it "hex" do
      expect(adapt_value("0x1F")).to eq(16 + 15)
    end

    it "float" do
      expect(adapt_value("3.14")).to eq(3.14)
    end

    it "float beginning with comma" do
      expect(adapt_value(".15")).to eq(0.15)
    end

    it "float with E" do
      expect(adapt_value("2e12")).to eq(2000000000000)
    end
  end

  describe "values of strings" do
    def nr_to_str(nr, original)
      str = nr.chr
      if str.respond_to?(:encode)
        str.encode('UTF-8', 'ISO-8859-1')
      elsif nr < 127
        str
      else
        original
      end
    end

    it "single-quoted" do
      expect(adapt_value("'foo'")).to eq('foo')
    end

    it "double-quoted" do
      expect(adapt_value('"bar"')).to eq("bar")
    end

    it "with special chars" do
      expect(adapt_value('"\n \t \r"')).to eq("\n \t \r")
    end

    it "with escaped quotes" do
      expect(adapt_value('" \" "')).to eq(' " ')
    end

    it "with latin1 octal escape" do
      expect(adapt_value('"\101 \251"')).to eq("A " + nr_to_str(0251, '\251'))
    end

    it "with latin1 hex escape" do
      expect(adapt_value('"\x41 \xA9"')).to eq("A " + nr_to_str(0xA9, '\xA9'))
    end

    it "with unicode escape" do
      expect(adapt_value('"\u00A9"')).to eq([0x00A9].pack("U"))
    end

    it "with multiple escapes together" do
      expect(adapt_value('"\xA0\u1680"')).to eq(nr_to_str(0xA0, '\xA0') + [0x1680].pack("U"))
    end

    it "with Ruby-like variable interpolation" do
      expect(adapt_value('"#{foo}"')).to eq('#{foo}')
    end
  end

  describe "values of regexes" do
    it "are left as is" do
      expect(adapt_value('/blah.*/')).to eq('/blah.*/')
    end
  end

  describe "values of boolens" do
    it "true" do
      expect(adapt_value('true')).to eq(true)
    end
    it "false" do
      expect(adapt_value('false')).to eq(false)
    end
  end

  describe "value of null" do
    it "is nil" do
      expect(adapt_value('null')).to eq(nil)
    end
  end

  def adapt_property(string)
    adapt(string)["expression"]["properties"][0]
  end

  describe "string properties" do
    it "don't use Ruby's eval()" do
      expect(adapt_property('({"foo#$%": 5})')["key"]["value"]).to eq('foo#$%')
    end
  end

  describe "getter property" do
    let(:property) { adapt_property('({get foo() { return this.x; } })') }

    it "gets parsed into get-kind" do
      expect(property["kind"]).to eq('get')
    end
    it "gets a function as its value" do
      expect(property["value"]["type"]).to eq('FunctionExpression')
    end
  end

  describe "setter property" do
    let(:property) { adapt_property('({set foo(x) { this.x = x; } })') }

    it "gets parsed into set-kind" do
      expect(property["kind"]).to eq('set')
    end
    it "gets a function as its value" do
      expect(property["value"]["type"]).to eq('FunctionExpression')
    end
  end

end
