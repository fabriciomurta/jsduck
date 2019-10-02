require "jsduck/js/ast"
require "jsduck/js/parser"

describe "JsDuck::Js::Ast detects method with" do
  def detect(string)
    node = JsDuck::Js::Parser.new(string).parse[0]
    return JsDuck::Js::Ast.new.detect(node[:code])
  end

  describe "name in" do
    it "function declaration" do
      expect(detect("/** */ function foo() {}")[:name]).to eq("foo")
    end

    it "function assignment" do
      expect(detect("/** */ foo = function() {}")[:name]).to eq("foo")
    end

    it "function assignment to object property" do
      expect(detect("/** */ some.item.foo = Ext.emptyFn")[:name]).to eq("some.item.foo")
    end

    it "Ext.emptyFn assignment" do
      expect(detect("/** */ foo = Ext.emptyFn")[:name]).to eq("foo")
    end

    it "var initialized with function" do
      expect(detect("/** */ var foo = function() {}")[:name]).to eq("foo")
    end

    it "var initialized with Ext.emptyFn" do
      expect(detect("/** */ var foo = Ext.emptyFn")[:name]).to eq("foo")
    end

    it "function expression with name" do
      expect(detect("/** */ (function foo(){})")[:name]).to eq("foo")
    end

    it "object property initialized with function" do
      expect(detect(<<-EOS)[:name]).to eq("foo")
        Foo = {
            /** */
            foo: function(){}
        };
      EOS
    end

    it "object property initialized with Ext.emptyFn" do
      expect(detect(<<-EOS)[:name]).to eq("foo")
        Foo = {
            /** */
            foo: Ext.emptyFn
        };
      EOS
    end

    it "object property with string key initialized with function" do
      expect(detect(<<-EOS)[:name]).to eq("foo")
        Foo = {
            /** */
            "foo": function(){}
        };
      EOS
    end
  end

  describe "no params in" do
    it "function declaration without params" do
      expect(detect("/** */ function foo() {}")[:params]).to eq(nil)
    end

    it "Ext.emptyFn assignment" do
      expect(detect("/** */ foo = Ext.emptyFn")[:params]).to eq(nil)
    end
  end

  describe "one param in" do
    it "function declaration with one param" do
      expect(detect("/** */ function foo(x) {}")[:params].length).to eq(1)
    end
  end

  describe "two params in" do
    it "function assignment with two params" do
      expect(detect("/** */ foo = function(a,b){}")[:params].length).to eq(2)
    end
  end

  describe "param names" do
    it "function assignment with three params" do
      params = detect("/** */ foo = function(a, b, c){}")[:params]
      expect(params[0]).to eq({:name => "a"})
      expect(params[1]).to eq({:name => "b"})
      expect(params[2]).to eq({:name => "c"})
    end
  end

end
