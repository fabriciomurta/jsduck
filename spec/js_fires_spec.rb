require "jsduck/js/parser"
require "jsduck/js/fires"
require "jsduck/js/node"

describe "JsDuck::Js::Fires" do
  def fires(string)
    docset = JsDuck::Js::Parser.new(string).parse[0]
    node = JsDuck::Js::Node.create(docset[:code])
    return JsDuck::Js::Fires.detect(node)
  end

  describe "detects fired events when function body" do
    it "has single this.fireEvent() statement" do
      expect(fires(<<-EOJS)).to eq(["click"])
        /** */
        function f() {
            this.fireEvent('click');
        }
      EOJS
    end

    it "has multiple this.fireEvent() statements" do
      expect(fires(<<-EOJS)).to eq(["click", "dblclick"])
        /** */
        function f() {
            this.fireEvent('click');
            var x = 10;
            this.fireEvent('dblclick');
        }
      EOJS
    end

    it "has this.fireEvent() inside control structures" do
      expect(fires(<<-EOJS)).to eq(["click", "dblclick"])
        /** */
        function f() {
            if (true) {
                while (x) {
                    this.fireEvent('click');
                }
            }
            else {
                this.fireEvent('dblclick');
            }
        }
      EOJS
    end

    it "has this.fireEvent() inside IF condition" do
      expect(fires(<<-EOJS)).to eq(["click"])
        /** */
        function f() {
            if (this.fireEvent('click') === false) {
                this.doSomething();
            }
        }
      EOJS
    end

    it "has this.fireEvent() inside inner function" do
      expect(fires(<<-EOJS)).to eq(["click"])
        /** */
        function f() {
            return (function () {
                this.fireEvent('click');
            })();
        }
      EOJS
    end

    it "has var me=this and me.fireEvent()" do
      expect(fires(<<-EOJS)).to eq(["click"])
        /** */
        function f() {
            var me = this;
            me.fireEvent('click');
        }
      EOJS
    end
  end

  describe "detects only unique events when function body" do
    it "has the same event fired multiple times" do
      expect(fires(<<-EOJS)).to eq(["blah", "click"])
        /** */
        function f() {
            this.fireEvent('click');
            this.fireEvent('click');
            this.fireEvent('blah');
            this.fireEvent('click');
            this.fireEvent('blah');
        }
      EOJS
    end
  end

  describe "detects no events being fired when function body" do
    it "is empty" do
      expect(fires("/** */ function foo() { }")).to eq([])
    end
  end

end
