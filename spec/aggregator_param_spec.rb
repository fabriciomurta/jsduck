require "mini_parser"

describe JsDuck::Aggregator do

  def parse(string)
    Helper::MiniParser.parse(string)
  end

  def parse_params(string)
    parse(string)["global"][:members][0][:params]
  end

  shared_examples_for "no parameters" do
    it "detects no params" do
      expect(@doc.length).to eq(0)
    end
  end

  shared_examples_for "two parameters" do
    it "detects parameter count" do
      expect(@doc.length).to eq(2)
    end

    it "detects parameter names" do
      expect(@doc[0][:name]).to eq("x")
      expect(@doc[1][:name]).to eq("y")
    end
  end

  shared_examples_for "parameter types" do
    it "detects parameter types" do
      expect(@doc[0][:type]).to eq("String")
      expect(@doc[1][:type]).to eq("Number")
    end
  end

  describe "explicit @method without @param-s" do
    before do
      @doc = parse_params(<<-EOS)
        /**
         * @method foo
         * Some function
         */
      EOS
    end
    it_should_behave_like "no parameters"
  end

  describe "function declaration without params" do
    before do
      @doc = parse_params("/** Some function */ function foo() {}")
    end
    it_should_behave_like "no parameters"
  end

  describe "function declaration with parameters" do
    before do
      @doc = parse_params("/** Some function */ function foo(x, y) {}")
    end
    it_should_behave_like "two parameters"
    it "parameter types default to Object" do
      expect(@doc[0][:type]).to eq("Object")
      expect(@doc[1][:type]).to eq("Object")
    end
  end

  describe "explicit @method with @param-s" do
    before do
      @doc = parse_params(<<-EOS)
        /**
         * @method foo
         * Some function
         * @param {String} x First parameter
         * @param {Number} y Second parameter
         */
      EOS
    end
    it_should_behave_like "two parameters"
    it_should_behave_like "parameter types"
  end

  describe "explicit @method with @param-s overriding implicit code" do
    before do
      @doc = parse_params(<<-EOS)
        /**
         * Some function
         * @param {String} x First parameter
         * @param {Number} y Second parameter
         * @method foo
         */
        function foo(q, z) {}
      EOS
    end
    it_should_behave_like "two parameters"
    it_should_behave_like "parameter types"
  end

  describe "explicit @method followed by function with another name" do
    before do
      @doc = parse_params(<<-EOS)
        /**
         * Some function
         * @method foo
         */
        function bar(x, y) {}
      EOS
    end
    it_should_behave_like "no parameters"
  end

  describe "explicit @param-s followed by more implicit params" do
    before do
      @doc = parse_params(<<-EOS)
        /**
         * Some function
         * @param {String} x
         * @param {Number} y
         */
        function foo(q, v, z) {}
      EOS
    end
    it_should_behave_like "two parameters"
  end

  describe "@param-s declaring only types" do
    before do
      @doc = parse_params(<<-EOS)
        /**
         * Some function
         * @param {String}
         * @param {Number}
         */
        function foo(x, y) {}
      EOS
    end

    it_should_behave_like "parameter types"

    it "detects no parameter names" do
      expect(@doc[0][:name]).to eq(nil)
      expect(@doc[1][:name]).to eq(nil)
    end
  end
end
