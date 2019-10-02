require "mini_parser"

describe JsDuck::Aggregator do
  def parse(string)
    Helper::MiniParser.parse(string)
  end

  def parse_member(string)
    parse(string)["global"][:members][0]
  end

  describe "@throws with type and description" do
    before do
      @doc = parse_member(<<-EOS)
        /**
         * Some function
         * @throws {Error} Some text
         * on multiple lines.
         */
        function bar() {}
      EOS
    end

    it "detects one throws tag" do
      expect(@doc[:throws].length).to eq(1)
    end

    it "detects type of exception" do
      expect(@doc[:throws][0][:type]).to eq("Error")
    end

    it "detects description" do
      expect(@doc[:throws][0][:doc]).to eq("Some text\non multiple lines.")
    end

    it "leaves documentation after @throws out of the main documentation" do
      expect(@doc[:doc]).to eq("Some function")
    end
  end

  describe "@throws without type" do
    before do
      @doc = parse_member(<<-EOS)
        /**
         * @throws Some description
         */
        function bar() {}
      EOS
    end

    it "detects type as Object" do
      expect(@doc[:throws][0][:type]).to eq("Object")
    end

    it "detects description" do
      expect(@doc[:throws][0][:doc]).to eq("Some description")
    end
  end

  describe "multiple @throws" do
    before do
      @doc = parse_member(<<-EOS)
        /**
         * @throws {Error} first
         * @throws {Error} second
         */
        function bar() {}
      EOS
    end

    it "detects two throws tags" do
      expect(@doc[:throws].length).to eq(2)
    end
  end

end
