require "jsduck/js/parser"
require "jsduck/js/method_calls"
require "jsduck/js/node"

describe "JsDuck::Js::MethodCalls" do
  def calls(string)
    docset = JsDuck::Js::Parser.new(string).parse[0]
    node = JsDuck::Js::Node.create(docset[:code])
    return JsDuck::Js::MethodCalls.detect(node)
  end

  describe "detects called methods when function body" do
    it "has method calls inside control structures" do
      expect(calls(<<-EOJS)).to eq(["alfa", "beta", "chico", "delta", "eeta"])
        /** */
        function f() {
            if (this.alfa()) {
                while (this.beta()) {
                    this.chico('Hello');
                }
            }
            else {
                return function() {
                    this.delta(1, 2, this.eeta());
                };
            }
        }
      EOJS
    end

    it "has var me=this and me.someMethod()" do
      expect(calls(<<-EOJS)).to eq(["someMethod"])
        /** */
        function f() {
            var me = this;
            me.someMethod('Blah');
        }
      EOJS
    end
  end

  describe "detects only unique methods when function body" do
    it "has the same method called multiple times" do
      expect(calls(<<-EOJS)).to eq(["blah", "click"])
        /** */
        function f() {
            this.click("a");
            this.click("b");
            this.blah();
            this.click("c");
            this.blah();
        }
      EOJS
    end
  end

  describe "detects no methods when function body" do
    it "is empty" do
      expect(calls("/** */ function foo() { }")).to eq([])
    end
  end

end
