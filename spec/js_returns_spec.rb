require "jsduck/js/parser"
require "jsduck/js/returns"

describe "JsDuck::Js::Returns#detect" do
  def returns(string)
    node = JsDuck::Js::Parser.new(string).parse[0]
    return JsDuck::Js::Returns::detect(node[:code])
  end

  describe "returns [:this] when function body" do
    it "has single RETURN THIS statement in body" do
      expect(returns("/** */ function foo() {return this;}")).to eq([:this])
    end

    it "has RETURN THIS after a few expression statements" do
      expect(returns(<<-EOJS)).to eq([:this])
      /** */
      function foo() {
          doSomething();
          i++;
          truthy ? foo() : bar();
          return this;
      }
      EOJS
    end

    it "has RETURN THIS after a few declarations" do
      expect(returns(<<-EOJS)).to eq([:this])
      /** */
      function foo() {
          var x = 10;
          function blah() {
          }
          return this;
      }
      EOJS
    end

    it "has RETURN THIS after an IF without RETURNs" do
      expect(returns(<<-EOJS)).to eq([:this])
      /** */
      function foo() {
          if (condition) {
              doSomething();
          } else {
              if (cond2) foo();
          }
          return this;
      }
      EOJS
    end

    it "has RETURN THIS after SWITCH without returns" do
      expect(returns(<<-EOJS)).to eq([:this])
      /** */
      function foo() {
          switch (x) {
              case 1: break;
              case 2: break;
              default: foo();
          }
          return this;
      }
      EOJS
    end

    it "has RETURN THIS after loops without returns" do
      expect(returns(<<-EOJS)).to eq([:this])
      /** */
      function foo() {
          for (i=0; i<10; i++) {
              for (j in i) {
                  doBlah();
              }
          }
          while (hoo) {
            do {
              sasa();
            } while(boo);
          }
          return this;
      }
      EOJS
    end

    it "has RETURN THIS after TRY CATCH without returns" do
      expect(returns(<<-EOJS)).to eq([:this])
      /** */
      function foo() {
          try {
            foo();
          } catch (e) {
            bar();
          } finally {
            baz();
          }
          return this;
      }
      EOJS
    end

    it "has RETURN THIS after WITH & BLOCK without returns" do
      expect(returns(<<-EOJS)).to eq([:this])
      /** */
      function foo() {
          with (x) {
            foo();
          }
          tada: {
            bar();
          }
          return this;
      }
      EOJS
    end

    it "has RETURN THIS after statements also containing a RETURN THIS" do
      expect(returns(<<-EOJS)).to eq([:this])
      /** */
      function foo() {
          while (x) {
            if (foo) {
            } else if (ooh) {
              return this;
            }
          }
          return this;
      }
      EOJS
    end

    it "has both branches of IF finishing with RETURN THIS" do
      expect(returns(<<-EOJS)).to eq([:this])
      /** */
      function foo() {
          if (foo) {
              blah();
              if (true) {
                  return this;
              } else {
                  chah();
                  return this;
              }
          } else {
              return this;
          }
      }
      EOJS
    end

    it "has DO WHILE containing RETURN THIS" do
      expect(returns(<<-EOJS)).to eq([:this])
      /** */
      function foo() {
          do {
              return this;
          } while(true);
      }
      EOJS
    end
  end

  describe "doesn't return [:this] when function body" do
    it "is empty" do
      returns("/** */ function foo() {}").should_not == [:this]
    end

    it "has empty return statement" do
      returns("/** */ function foo() { return; }").should_not == [:this]
    end

    it "has RETURN THIS after statements containing a RETURN" do
      returns(<<-EOJS).should_not == [:this]
      /** */
      function foo() {
          while (x) {
            if (foo) {
            } else if (ooh) {
              return whoKnowsWhat;
            }
          }
          return this;
      }
      EOJS
    end

    it "has WHILE containing RETURN THIS" do
      returns(<<-EOJS).should_not == [:this]
      /** */
      function foo() {
          while (condition) {
              return this;
          };
      }
      EOJS
    end

    it "has only one branch finishing with RETURN THIS" do
      returns(<<-EOJS).should_not == [:this]
      /** */
      function foo() {
          if (foo) {
              doSomething();
          } else {
              return this;
          }
      }
      EOJS
    end
  end

  describe "returns ['undefined'] when function body" do
    it "is empty" do
      expect(returns("/** */ function foo() {}")).to eq(["undefined"])
    end

    it "has no return statement" do
      expect(returns("/** */ function foo() { bar(); baz(); }")).to eq(["undefined"])
    end

    it "has empty return statement" do
      expect(returns("/** */ function foo() { return; }")).to eq(["undefined"])
    end

    it "has RETURN UNDEFINED statement" do
      expect(returns("/** */ function foo() { return undefined; }")).to eq(["undefined"])
    end

    it "has RETURN VOID statement" do
      expect(returns("/** */ function foo() { return void(blah); }")).to eq(["undefined"])
    end
  end

  describe "returns ['Boolean'] when function body" do
    it "returns true" do
      expect(returns("/** */ function foo() { return true; }")).to eq(["Boolean"])
    end

    it "returns false" do
      expect(returns("/** */ function foo() { return false; }")).to eq(["Boolean"])
    end

    it "returns negation" do
      expect(returns("/** */ function foo() { return !foo; }")).to eq(["Boolean"])
    end

    it "returns > comparison" do
      expect(returns("/** */ function foo() { return x > y; }")).to eq(["Boolean"])
    end

    it "returns <= comparison" do
      expect(returns("/** */ function foo() { return x <= y; }")).to eq(["Boolean"])
    end

    it "returns == comparison" do
      expect(returns("/** */ function foo() { return x == y; }")).to eq(["Boolean"])
    end

    it "returns 'in' expression" do
      expect(returns("/** */ function foo() { return key in object; }")).to eq(["Boolean"])
    end

    it "returns 'instanceof' expression" do
      expect(returns("/** */ function foo() { return obj instanceof cls; }")).to eq(["Boolean"])
    end

    it "returns 'delete' expression" do
      expect(returns("/** */ function foo() { return delete foo[bar]; }")).to eq(["Boolean"])
    end

    it "returns conjunction of boolean expressions" do
      expect(returns("/** */ function foo() { return x > y && y > z; }")).to eq(["Boolean"])
    end

    it "returns disjunction of boolean expressions" do
      expect(returns("/** */ function foo() { return x == y || y == z; }")).to eq(["Boolean"])
    end

    it "returns conditional expression evaluating to boolean" do
      expect(returns("/** */ function foo() { return x ? true : a > b; }")).to eq(["Boolean"])
    end

    it "returns assignment of boolean" do
      expect(returns("/** */ function foo() { return x = true; }")).to eq(["Boolean"])
    end
  end

  describe "returns ['String'] when function body" do
    it "returns a string literal" do
      expect(returns("/** */ function foo() { return 'foo'; }")).to eq(["String"])
    end

    it "returns a string concatenation" do
      expect(returns("/** */ function foo() { return 'foo' + 'bar'; }")).to eq(["String"])
    end

    it "returns a string concatenated with number" do
      expect(returns("/** */ function foo() { return 'foo' + 7; }")).to eq(["String"])
    end

    it "returns a number concatenated with string" do
      expect(returns("/** */ function foo() { return 8 + 'foo'; }")).to eq(["String"])
    end

    it "returns a typeof expression" do
      expect(returns("/** */ function foo() { return typeof 8; }")).to eq(["String"])
    end
  end

  describe "returns ['RegExp'] when function body" do
    it "returns a regex literal" do
      expect(returns("/** */ function foo() { return /.*/; }")).to eq(["RegExp"])
    end
  end

end
