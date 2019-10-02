require "jsduck/js/ast"
require "jsduck/js/parser"

describe "JsDuck::Js::Ast detecting" do
  def detect(string)
    node = JsDuck::Js::Parser.new(string).parse[0]
    return JsDuck::Js::Ast.new.detect(node[:code])
  end

  describe "Ext.define()" do
    let (:members) do
      detect(<<-EOS)[:members]
        /** */
        Ext.define('MyClass', {
            statics: {
                foo: true,
                bar: function(){}
            }
        });
      EOS
    end

    it "finds two members" do
      expect(members.length).to eq(2)
    end

    describe "finds property" do
      it "with :property tagname" do
        expect(members[0][:tagname]).to eq(:property)
      end
      it "with name" do
        expect(members[0][:name]).to eq("foo")
      end
      it "with :static flag" do
        expect(members[0][:static]).to eq(true)
      end
    end

    describe "finds method" do
      it "with :property tagname" do
        expect(members[1][:tagname]).to eq(:method)
      end
      it "with name" do
        expect(members[1][:name]).to eq("bar")
      end
      it "with :static flag" do
        expect(members[1][:static]).to eq(true)
      end
    end

  end

end
