require "mini_parser"

describe JsDuck::Aggregator do
  def parse(string)
    Helper::MiniParser.parse(string)
  end

  def parse_member(string)
    parse(string)["global"][:members][0]
  end

  describe "member with @protected" do
    before do
      @doc = parse_member("/** @protected */")
    end

    it "gets protected attribute" do
      expect(@doc[:protected]).to eq(true)
    end
  end

  describe "member with @abstract" do
    before do
      @doc = parse_member("/** @abstract */")
    end

    it "gets abstract attribute" do
      expect(@doc[:abstract]).to eq(true)
    end
  end

  describe "member with @static" do
    before do
      @doc = parse_member("/** @static */")
    end

    it "gets static attribute" do
      expect(@doc[:static]).to eq(true)
    end
  end

  describe "method with @template" do
    before do
      @doc = parse_member(<<-EOS)
        /**
         * @method foo
         * Some function
         * @template
         */
      EOS
    end
    it "gets template attribute" do
      expect(@doc[:template]).to eq(true)
    end
  end

  describe "event with @preventable" do
    before do
      @doc = parse_member(<<-EOS)
        /**
         * @event foo
         * @preventable bla blah
         * Some event
         */
      EOS
    end
    it "gets preventable attribute" do
      expect(@doc[:preventable]).to eq(true)
    end
    it "ignores text right after @preventable" do
      expect(@doc[:doc]).to eq("Some event")
    end
  end

  describe "member with @deprecated" do
    before do
      @deprecated = parse_member(<<-EOS)[:deprecated]
        /**
         * @deprecated 4.0 Use escapeRegex instead.
         */
      EOS
    end

    it "gets deprecated attribute" do
      expect(@deprecated).not_to eq(nil)
    end

    it "detects deprecation description" do
      expect(@deprecated[:text]).to eq("Use escapeRegex instead.")
    end

    it "detects version of deprecation" do
      expect(@deprecated[:version]).to eq("4.0")
    end
  end

  describe "member with @deprecated without version number" do
    before do
      @deprecated = parse_member(<<-EOS)[:deprecated]
        /**
         * @deprecated Use escapeRegex instead.
         */
      EOS
    end

    it "doesn't detect version number" do
      expect(@deprecated[:version]).to eq(nil)
    end

    it "still detects description" do
      expect(@deprecated[:text]).to eq("Use escapeRegex instead.")
    end
  end

  describe "class with @markdown" do
    before do
      @doc = parse(<<-EOS)["MyClass"]
        /**
         * @class MyClass
         * @markdown
         * Comment here.
         */
      EOS
    end

    it "does not show @markdown tag in docs" do
      expect(@doc[:doc]).to eq("Comment here.")
    end
  end

end
