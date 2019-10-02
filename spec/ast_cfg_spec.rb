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
            config: {
                foo: true,
                bar: 5
            }
        });
      EOS
    end

    it "adds :members as array" do
      members.should be_kind_of(Array)
    end

    it "finds two cfgs" do
      expect(members[0][:tagname]).to eq(:cfg)
      expect(members[1][:tagname]).to eq(:cfg)
    end

    it "finds cfg foo" do
      expect(members[0][:name]).to eq("foo")
    end

    it "finds cfg bar" do
      expect(members[1][:name]).to eq("bar")
    end
  end

end
