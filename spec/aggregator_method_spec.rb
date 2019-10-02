require "mini_parser"

describe JsDuck::Aggregator do

  def parse(string)
    Helper::MiniParser.parse(string)
  end

  def parse_method(string)
    parse(string)["global"][:members][0]
  end

  shared_examples_for "method" do
    it "creates method" do
      expect(@doc[:tagname]).to eq(:method)
    end

    it "takes documentation from doc-comment" do
      expect(@doc[:doc]).to eq("Some function")
    end

    it "detects method name" do
      expect(@doc[:name]).to eq("foo")
    end
  end

  describe "explicit method" do
    before do
      @doc = parse_method(<<-EOS)
        /**
         * @method foo
         * Some function
         */
      EOS
    end
    it_should_behave_like "method"
  end

  describe "explicit @method after @params-s" do
    before do
      @doc = parse_method(<<-EOS)
        /**
         * Some function
         * @param {String} x First parameter
         * @param {Number} y Second parameter
         * @method foo
         */
      EOS
    end
    it_should_behave_like "method"
  end

  describe "explicit @method followed by function with another name" do
    before do
      @doc = parse_method(<<-EOS)
        /**
         * Some function
         * @method foo
         */
        function bar(x, y) {}
      EOS
    end
    it_should_behave_like "method"
  end

  describe "function declaration" do
    before do
      @doc = parse_method("/** Some function */ function foo() {}")
    end
    it_should_behave_like "method"
  end

  describe "function-literal with var" do
    before do
      @doc = parse_method("/** Some function */ var foo = function() {}")
    end
    it_should_behave_like "method"
  end

  describe "function-literal without var" do
    before do
      @doc = parse_method("/** Some function */ foo = function() {}")
    end
    it_should_behave_like "method"
  end

  describe "function-literal in object-literal" do
    before do
      @doc = parse_method("({ /** Some function */ foo: function() {} })")
    end
    it_should_behave_like "method"
  end

  describe "function-literal in object-literal-string" do
    before do
      @doc = parse_method("({ /** Some function */ 'foo': function() {} })")
    end
    it_should_behave_like "method"
  end

  describe "function-literal in prototype-chain" do
    before do
      @doc = parse_method("/** Some function */ Some.verylong.prototype.foo = function() {}")
    end
    it_should_behave_like "method"
  end

  describe "function-literal in comma-first style" do
    before do
      @doc = parse_method("({ blah: 7 /** Some function */ , foo: function() {} })")
    end
    it_should_behave_like "method"
  end

  describe "Ext.emptyFn in object-literal" do
    before do
      @doc = parse_method("({ /** Some function */ foo: Ext.emptyFn })")
    end
    it_should_behave_like "method"
  end

  describe "Object.defineProperty with function value" do
    before do
      @doc = parse_method(<<-EOS)
        /** Some function */
        Object.defineProperty(this, 'foo', {
          writable: false,
          value: function() { return true; }
        });
      EOS
    end
    it_should_behave_like "method"
  end

  describe "doc-comment followed by 'function'" do
    before do
      @doc = parse_method("/** Some function */ 'function';")
    end

    it "isn't detected as method" do
      expect(@doc[:tagname]).not_to eq(:method)
    end
  end

  describe "Doc-comment not followed by function but containing @return" do
    before do
      @doc = parse_method(<<-EOS)
        /**
         * Some function
         * @returns {String} return value
         */
        var foo = Ext.emptyFn;
      EOS
    end
    it_should_behave_like "method"
  end

  describe "Doc-comment not followed by function but containing @param" do
    before do
      @doc = parse_method(<<-EOS)
        /**
         * Some function
         * @param {String} x
         */
        var foo = Ext.emptyFn;
      EOS
    end
    it_should_behave_like "method"
  end

  describe "method without doc-comment" do
    before do
      @docs = parse(<<-EOS)
        // My comment
        function foo(x, y) {}
      EOS
    end
    it "remains undocumented" do
      expect(@docs.length).to eq(0)
    end
  end

  shared_examples_for "auto detected method" do
    it "detects a method" do
      expect(method[:tagname]).to eq(:method)
    end

    it "detects method name" do
      expect(method[:name]).to eq('foo')
    end

    it "flags method with :inheritdoc" do
      expect(method[:inheritdoc]).to eq({})
    end

    it "flags method as :autodetected" do
      expect(method[:autodetected][:tagname]).to eq(:method)
    end
  end

  describe "method without comment inside Ext.define" do
    let(:method) do
      parse(<<-EOS)["MyClass"][:members][0]
        /** @class Ext.Base */

        /** Some documentation. */
        Ext.define("MyClass", {
            foo: function() {}
        });
      EOS
    end

    it_should_behave_like "auto detected method"
  end

  describe "method with line comment inside Ext.define" do
    let(:method) do
      parse(<<-EOS)["MyClass"][:members][0]
        /** @class Ext.Base */

        /** Some documentation. */
        Ext.define("MyClass", {
            // My docs
            foo: function() {}
        });
      EOS
    end

    it_should_behave_like "auto detected method"

    it "detects method documentation" do
      expect(method[:doc]).to eq('My docs')
    end
  end

  describe "property with value Ext.emptyFn inside Ext.define" do
    let(:method) do
      parse(<<-EOS)["MyClass"][:members][0]
        /** @class Ext.Base */

        /** Some documentation. */
        Ext.define("MyClass", {
            foo: Ext.emptyFn
        });
      EOS
    end

    it "detects a method" do
      expect(method[:tagname]).to eq(:method)
    end
  end

  describe "method without comment inside Ext.extend" do
    let(:method) do
      parse(<<-EOS)["MyClass"][:members][0]
        /** Some documentation. */
        MyClass = Ext.extend(Object, {
            foo: function(){}
        });
      EOS
    end

    it_should_behave_like "auto detected method"
  end

  describe "method with line comment inside Ext.extend" do
    let(:method) do
      parse(<<-EOS)["MyClass"][:members][0]
        /** Some documentation. */
        MyClass = Ext.extend(Object, {
            // My docs
            foo: function(){}
        });
      EOS
    end

    it_should_behave_like "auto detected method"

    it "detects method documentation" do
      expect(method[:doc]).to eq('My docs')
    end
  end

  describe "method without comment inside object literal" do
    let(:method) do
      parse(<<-EOS)["MyClass"][:members][0]
        /** Some documentation. */
        MyClass = {
            foo: function(){}
        };
      EOS
    end

    it_should_behave_like "auto detected method"
  end

  describe "method with line comment inside object literal" do
    let(:method) do
      parse(<<-EOS)["MyClass"][:members][0]
        /** Some documentation. */
        MyClass = {
            // My docs
            foo: function(){}
        };
      EOS
    end

    it_should_behave_like "auto detected method"

    it "detects method documentation" do
      expect(method[:doc]).to eq('My docs')
    end
  end

  describe "method inside object literal marked with @class" do
    let(:method) do
      parse(<<-EOS)["MyClass"][:members][0]
        /**
         * @class MyClass
         * Some documentation.
         */
        createClass("MyClass", /** @class MyClass */ {
            foo: function(){}
        });
      EOS
    end

    it_should_behave_like "auto detected method"
  end

end
