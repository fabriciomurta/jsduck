require "jsduck/base_type"
require "jsduck/doc/map"
require "jsduck/js/ast"
require "jsduck/js/parser"
require "jsduck/css/parser"
require "jsduck/doc/parser"

describe JsDuck::BaseType do
  def detect(string, type = :js)
    if type == :css
      node = JsDuck::Css::Parser.new(string).parse[0]
    else
      node = JsDuck::Js::Parser.new(string).parse[0]
      node[:code] = JsDuck::Js::Ast.new.detect(node[:code])
    end

    doc_parser = JsDuck::Doc::Parser.new
    node[:comment] = doc_parser.parse(node[:comment])
    node[:doc_map] = JsDuck::Doc::Map.build(node[:comment])
    return JsDuck::BaseType.detect(node[:doc_map], node[:code])
  end

  describe "detects as class" do
    it "@class tag" do
      expect(detect("/** @class */")).to eq(:class)
    end

    it "class-like function" do
      expect(detect("/** */ function MyClass() {}")).to eq(:class)
    end

    it "Ext.define()" do
      expect(detect(<<-EOS)).to eq(:class)
        /** */
        Ext.define('MyClass', {
        });
      EOS
    end
  end

  describe "detects as method" do
    it "@method tag" do
      expect(detect("/** @method */")).to eq(:method)
    end

    it "@constructor tag" do
      expect(detect("/** @constructor */")).to eq(:method)
    end

    it "@param tag" do
      expect(detect("/** @param {Number} x */")).to eq(:method)
    end

    it "@return tag" do
      expect(detect("/** @return {Boolean} */")).to eq(:method)
    end

    it "function declaration" do
      expect(detect("/** */ function foo() {}")).to eq(:method)
    end
  end

  describe "detects as event" do
    it "@event tag" do
      expect(detect("/** @event */")).to eq(:event)
    end

    it "@event and @param tags" do
      expect(detect("/** @event @param {Number} x */")).to eq(:event)
    end
  end

  describe "detects as config" do
    it "@cfg tag" do
      expect(detect("/** @cfg */")).to eq(:cfg)
    end
  end

  describe "detects as property" do
    it "@property tag" do
      expect(detect("/** @property */")).to eq(:property)
    end

    it "@type tag" do
      expect(detect("/** @type Foo */")).to eq(:property)
    end

    it "empty doc-comment with no code" do
      expect(detect("/** */")).to eq(:property)
    end
  end

  describe "detects as css variable" do
    it "@var tag" do
      expect(detect("/** @var */")).to eq(:css_var)
    end
  end

  describe "detects as css mixin" do
    it "@mixin in code" do
      expect(detect("/** */ @mixin foo-bar {}", :css)).to eq(:css_mixin)
    end

    it "@param in doc and @mixin in code" do
      expect(detect("/** @param {number} $foo */ @mixin foo-bar {}", :css)).to eq(:css_mixin)
    end
  end

end
