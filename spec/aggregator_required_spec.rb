require "mini_parser"

describe JsDuck::Aggregator do
  def parse(string)
    Helper::MiniParser.parse(string)
  end

  def parse_member(string)
    parse(string)["global"][:members][0]
  end

  describe "a normal config option" do
    before do
      @doc = parse_member(<<-EOS)
        /**
         * @cfg foo Something
         */
      EOS
    end
    it "is not required by default" do
      expect(@doc[:required]).not_to eq(true)
    end
  end

  describe "a config option labeled as required" do
    before do
      @doc = parse_member(<<-EOS)
        /**
         * @cfg foo (required) Something
         */
      EOS
    end
    it "has required flag set to true" do
      expect(@doc[:required]).to eq(true)
    end
  end

  describe "a class with @cfg (required)" do
    before do
      @doc = parse(<<-EOS)["MyClass"]
        /**
         * @class MyClass
         * @cfg foo (required)
         */
      EOS
    end
    it "doesn't become a required class" do
      expect(@doc[:required]).not_to eq(true)
    end
    it "contains required config" do
      expect(@doc[:members][0][:required]).to eq(true)
    end
  end

  describe "a config subproperty labeled with (required)" do
    before do
      @doc = parse_member(<<-EOS)
        /**
         * @cfg foo Something
         * @cfg foo.bar (required) Subproperty
         */
      EOS
    end

    it "doesn't have the config marked as required" do
      expect(@doc[:required]).not_to eq(true)
    end

    it "doesn't have the subproperty marked as required" do
      expect(@doc[:properties][0][:required]).not_to eq(true)
    end

    it "contains the (required) inside subproperty description" do
      expect(@doc[:properties][0][:doc]).to eq("(required) Subproperty")
    end
  end

end
