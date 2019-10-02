require "mini_parser"

describe JsDuck::Aggregator do
  def parse(string)
    Helper::MiniParser.parse(string, :fires => true)
  end

  def parse_fires(string, cls_name = "global")
    parse(string)[cls_name][:members][0][:fires]
  end

  describe "@fires with single event" do
    before do
      @fires = parse_fires(<<-EOS)
        /**
         * Some function
         * @fires click
         */
        function bar() {}
      EOS
    end

    it "detects one fired event" do
      expect(@fires.length).to eq(1)
    end

    it "detects event name that's fired" do
      expect(@fires[0]).to eq("click")
    end
  end

  describe "@fires with multiple events" do
    before do
      @fires = parse_fires(<<-EOS)
        /**
         * @fires click dblclick
         */
        function bar() {}
      EOS
    end

    it "detects two events" do
      expect(@fires.length).to eq(2)
    end

    it "detects event names" do
      expect(@fires[0]).to eq("click")
      expect(@fires[1]).to eq("dblclick")
    end
  end

  describe "multiple @fires tags" do
    before do
      @fires = parse_fires(<<-EOS)
        /**
         * @fires click
         * @fires dblclick
         */
        function bar() {}
      EOS
    end

    it "detects two events" do
      expect(@fires.length).to eq(2)
    end

    it "detects event names" do
      expect(@fires[0]).to eq("click")
      expect(@fires[1]).to eq("dblclick")
    end
  end

  describe "this.fireEvent() in code" do
    before do
      @fires = parse_fires(<<-EOS)
        /** */
        function bar() {
            this.fireEvent("click");
        }
      EOS
    end

    it "detects event from code" do
      expect(@fires[0]).to eq("click")
    end
  end

  describe "method calling another method which fires an event" do
    let(:fires) do
      parse_fires(<<-EOS, "Foo")
        /** @class Foo */

        /** */
        function foo() {
            this.bar();
            this.fireEvent("click")
        }

        /** */
        function bar() {
            this.fireEvent("dblclick");
        }
      EOS
    end

    it "lists events fired by both methods" do
      expect(fires).to eq(["click", "dblclick"])
    end
  end

  describe "method calling itself" do
    let(:fires) do
      parse_fires(<<-EOS, "Foo")
        /** @class Foo */

        /** */
        function foo() {
            this.foo();
            this.fireEvent("click")
        }
      EOS
    end

    it "lists just the event fired by himself" do
      expect(fires).to eq(["click"])
    end
  end

  describe "method calling another method that calls yet another method" do
    let(:fires) do
      parse_fires(<<-EOS, "Foo")
        /** @class Foo */

        /** */
        function foo() {
            this.bar();
            this.fireEvent("click")
        }

        /** */
        function bar() {
            this.baz();
            this.fireEvent("dblclick");
        }

        /** */
        function baz() {
            this.fireEvent("exit");
        }
      EOS
    end

    it "lists events fired by all the methods" do
      expect(fires).to eq(["click", "dblclick", "exit"])
    end
  end

  describe "method with explicit @fires" do
    let(:fires) do
      parse_fires(<<-EOS, "Foo")
        /** @class Foo */

        /** @fires huh */
        function foo() {
            this.bar();
            this.fireEvent("click")
        }

        /** */
        function bar() {
            this.fireEvent("dblclick");
        }
      EOS
    end

    it "blocks lookup of events fired by called methods" do
      expect(fires).to eq(["huh"])
    end
  end

end
