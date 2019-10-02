require "jsduck/js/ast"
require "jsduck/js/parser"

describe "JsDuck::Js::Ast detects property with" do
  def detect(string)
    node = JsDuck::Js::Parser.new(string).parse[0]
    return JsDuck::Js::Ast.new.detect(node[:code])
  end

  describe "name in" do
    it "var declaration" do
      expect(detect("/** */ var foo;")[:name]).to eq("foo")
    end

    it "var declaration with initialization" do
      expect(detect("/** */ foo = 5;")[:name]).to eq("foo")
    end

    it "assignment to var" do
      expect(detect("/** */ foo = 5;")[:name]).to eq("foo")
    end

    it "assignment to object property" do
      expect(detect("/** */ foo.bar.baz = 5;")[:name]).to eq("foo.bar.baz")
    end

    it "object property" do
      expect(detect(<<-EOS)[:name]).to eq("foo")
        Foo = {
            /** */
            foo: 5
        };
      EOS
    end

    it "object with string key" do
      expect(detect(<<-EOS)[:name]).to eq("foo")
        Foo = {
            /** */
            "foo": 5
        };
      EOS
    end

    it "lonely identifier" do
      expect(detect("/** */ foo;")[:name]).to eq("foo")
    end

    it "lonely string" do
      expect(detect("/** */ 'foo';")[:name]).to eq("foo")
    end

    it "string as function argument" do
      expect(detect(<<-EOS)[:name]).to eq("foo")
        this.addEvents(
            /** */
            "foo"
        );
      EOS
    end
  end

  describe "type in var initialized with" do
    it "int" do
      expect(detect("/** */ var foo = 5;")[:type]).to eq("Number")
    end

    it "float" do
      expect(detect("/** */ var foo = 0.5;")[:type]).to eq("Number")
    end

    it "string" do
      expect(detect("/** */ var foo = 'haa';")[:type]).to eq("String")
    end

    it "true" do
      expect(detect("/** */ var foo = true;")[:type]).to eq("Boolean")
    end

    it "false" do
      expect(detect("/** */ var foo = false;")[:type]).to eq("Boolean")
    end

    it "regex" do
      expect(detect("/** */ var foo = /abc/g;")[:type]).to eq("RegExp")
    end

    it "array" do
      expect(detect("/** */ var foo = [];")[:type]).to eq("Array")
    end

    it "object" do
      expect(detect("/** */ var foo = {};")[:type]).to eq("Object")
    end
  end

  describe "no type in" do
    it "uninitialized var declaration" do
      expect(detect("/** */ var foo;")[:type]).to eq(nil)
    end
  end

  describe "default value in" do
    it "var initialization with string" do
      expect(detect("/** */ var foo = 'bar';")[:default]).to eq("'bar'")
    end

    it "assignment with number" do
      expect(detect("/** */ foo = 15;")[:default]).to eq("15")
    end

    it "assignment with number 0" do
      expect(detect("/** */ foo = 0;")[:default]).to eq("0")
    end

    it "assignment with boolean true" do
      expect(detect("/** */ foo = true;")[:default]).to eq("true")
    end

    it "assignment with boolean false" do
      expect(detect("/** */ foo = false;")[:default]).to eq("false")
    end

    it "assignment with regex" do
      expect(detect("/** */ foo = /abc/;")[:default]).to eq("/abc/")
    end

    it "assignment with object" do
      expect(detect("/** */ foo = {bar: 5};")[:default]).to eq("{bar: 5}")
    end

    it "object property with array" do
      expect(detect("X = { /** */ foo: [1, 2, 3] };")[:default]).to eq("[1, 2, 3]")
    end
  end

  describe "no default value in" do
    it "var without initialization" do
      expect(detect("/** */ var foo;")[:default]).to eq(nil)
    end

    it "assignment of function call" do
      expect(detect("/** */ foo = bar();")[:default]).to eq(nil)
    end

    it "object property with array containing function" do
      expect(detect("X = { /** */ foo: [1, 2, function(){}] };")[:default]).to eq(nil)
    end
  end

end
