require "mini_parser"

describe JsDuck::Aggregator do

  def parse(string)
    Helper::MiniParser.parse(string)
  end

  def parse_member(string)
    parse(string)["global"][:members][0]
  end

  describe "method without @return" do
    before do
      @doc = parse_member(<<-EOS)
        /**
         * Some function
         */
        function foo() {}
      EOS
    end
    it "defaults return field to nil" do
      expect(@doc[:return]).to eq(nil)
    end
  end

  describe "method with @return that has no type" do
    before do
      @doc = parse_member(<<-EOS)
        /**
         * Some function
         * @return Some value.
         */
        function foo() {}
      EOS
    end
    it "defaults return type to Object" do
      expect(@doc[:return][:type]).to eq("Object")
    end
    it "recognizes documentation of return value" do
      expect(@doc[:return][:doc]).to eq("Some value.")
    end
  end

  shared_examples_for "has return" do
    it "detects return type" do
      expect(@doc[:return][:type]).to eq("String")
    end
    it "detects return value comment" do
      expect(@doc[:return][:doc]).to eq("return value")
    end
  end

  describe "@return documenting return value" do
    before do
      @doc = parse_member(<<-EOS)
        /**
         * Some function
         * @return {String} return value
         */
        function foo() {}
      EOS
    end
    it_should_behave_like "has return"
  end

  describe "@returns being alias for @return" do
    before do
      @doc = parse_member(<<-EOS)
        /**
         * Some function
         * @returns {String} return value
         */
        function foo() {}
      EOS
    end
    it_should_behave_like "has return"
  end

end
