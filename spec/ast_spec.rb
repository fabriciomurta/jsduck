require "jsduck/js/ast"
require "jsduck/js/parser"

describe JsDuck::Js::Ast do
  def detect(string)
    node = JsDuck::Js::Parser.new(string).parse[0]
    return JsDuck::Js::Ast.new.detect(node[:code])[:tagname]
  end

  describe "detects as class" do
    it "function beginning with uppercase letter" do
      expect(detect("/** */ function MyClass() {}")).to eq(:class)
    end

    it "function assignment to uppercase name" do
      expect(detect("/** */ MyClass = function() {}")).to eq(:class)
    end

    it "function assignment to uppercase property" do
      expect(detect("/** */ foo.MyClass = function() {}")).to eq(:class)
    end

    it "uppercase var initialization with function" do
      expect(detect("/** */ var MyClass = function() {}")).to eq(:class)
    end

    it "object literal assignment to uppercase name" do
      expect(detect("/** */ MyClass = {};")).to eq(:class)
    end

    it "doc-comment right before object literal" do
      expect(detect("MyClass = makeClass( /** */ {} );")).to eq(:class)
    end

    it "Ext.extend()" do
      expect(detect("/** */ MyClass = Ext.extend(Your.Class, {  });")).to eq(:class)
    end

    it "var initialized with Ext.extend()" do
      expect(detect("/** */ var MyClass = Ext.extend(Your.Class, {  });")).to eq(:class)
    end

    it "Ext.extend() assigned to lowercase name" do
      expect(detect("/** */ myclass = Ext.extend(Your.Class, {  });")).to eq(:class)
    end

    it "lowercase var initialized with Ext.extend()" do
      expect(detect("/** */ var myclass = Ext.extend(Your.Class, {  });")).to eq(:class)
    end

    it "Ext.define()" do
      expect(detect(<<-EOS)).to eq(:class)
        /** */
        Ext.define('MyClass', {
        });
      EOS
    end

    it "Ext.ClassManager.create()" do
      expect(detect(<<-EOS)).to eq(:class)
        /** */
        Ext.ClassManager.create('MyClass', {
        });
      EOS
    end
  end

  describe "detects as method" do
    it "function beginning with underscore" do
      expect(detect("/** */ function _Foo() {}")).to eq(:method)
    end

    it "lowercase function name" do
      expect(detect("/** */ function foo() {}")).to eq(:method)
    end

    it "assignment of function" do
      expect(detect("/** */ foo = function() {}")).to eq(:method)
    end

    it "assignment of Ext.emptyFn" do
      expect(detect("/** */ foo = Ext.emptyFn")).to eq(:method)
    end

    it "var initialized with function" do
      expect(detect("/** */ var foo = function() {}")).to eq(:method)
    end

    it "var initialized with Ext.emptyFn" do
      expect(detect("/** */ var foo = Ext.emptyFn")).to eq(:method)
    end

    it "anonymous function as expression" do
      expect(detect("/** */ (function(){})")).to eq(:method)
    end

    it "anonymous function as parameter" do
      expect(detect("doSomething('blah', /** */ function(){});")).to eq(:method)
    end

    it "object property initialized with function" do
      expect(detect(<<-EOS)).to eq(:method)
        Foo = {
            /** */
            bar: function(){}
        };
      EOS
    end

    it "object property in comma-first notation initialized with function" do
      expect(detect(<<-EOS)).to eq(:method)
        Foo = {
            foo: 5
            /** */
            , bar: function(){}
        };
      EOS
    end

    it "object property initialized with Ext.emptyFn" do
      expect(detect(<<-EOS)).to eq(:method)
        Foo = {
            /** */
            bar: Ext.emptyFn
        };
      EOS
    end
  end

  describe "detects as property" do
    it "no code" do
      expect(detect("/** */")).to eq(:property)
    end
  end

end
