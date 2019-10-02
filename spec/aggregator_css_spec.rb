require "mini_parser"

describe JsDuck::Aggregator do

  def parse(string)
    Helper::MiniParser.parse(string, {:filename => ".scss"})
  end

  def parse_member(string)
    parse(string)["global"][:members][0]
  end

  describe "CSS with @var in doc-comment" do
    before do
      @doc = parse_member(<<-EOCSS)
        /**
         * @var {number} $button-height Default height for buttons.
         */
      EOCSS
    end

    it "detects variable" do
      expect(@doc[:tagname]).to eq(:css_var)
    end
    it "detects variable name" do
      expect(@doc[:name]).to eq("$button-height")
    end
    it "detects variable type" do
      expect(@doc[:type]).to eq("number")
    end
    it "detects variable description" do
      expect(@doc[:doc]).to eq("Default height for buttons.")
    end
  end

  describe "CSS @var with @member" do
    before do
      @doc = parse(<<-EOCSS)["Ext.Button"][:members][0]
        /**
         * @var {number} $button-height Default height for buttons.
         * @member Ext.Button
         */
      EOCSS
    end

    it "detects owner" do
      expect(@doc[:owner]).to eq("Ext.Button")
    end
  end

  describe "CSS @var with explicit default value" do
    before do
      @doc = parse_member(<<-EOCSS)
        /**
         * @var {number} [$button-height=25px]
         */
      EOCSS
    end

    it "detects default value" do
      expect(@doc[:default]).to eq("25px")
    end
  end

  describe "CSS doc-comment followed with $var-name:" do
    before do
      @doc = parse_member(<<-EOCSS)
        /**
         * Default height for buttons.
         */
        $button-height: 25px;
      EOCSS
    end

    it "detects variable" do
      expect(@doc[:tagname]).to eq(:css_var)
    end
    it "detects variable name" do
      expect(@doc[:name]).to eq("$button-height")
    end
    it "detects variable type" do
      expect(@doc[:type]).to eq("number")
    end
    it "detects variable default value" do
      expect(@doc[:default]).to eq("25px")
    end
  end

  describe "CSS doc-comment followed by @mixin" do
    before do
      @doc = parse_member(<<-EOCSS)
        /**
         * Creates an awesome button.
         *
         * @param {string} $ui-label The name of the UI being created.
         * @param {color} $color Base color for the UI.
         */
        @mixin my-button {
        }
      EOCSS
    end

    it "detects mixin" do
      expect(@doc[:tagname]).to eq(:css_mixin)
    end
    it "detects mixin name" do
      expect(@doc[:name]).to eq("my-button")
    end
    it "detects mixin description" do
      expect(@doc[:doc]).to eq("Creates an awesome button.")
    end
    it "detects mixin parameters" do
      expect(@doc[:params].length).to eq(2)
    end
    it "detects mixin param name" do
      expect(@doc[:params][0][:name]).to eq("$ui-label")
    end
    it "detects mixin param type" do
      expect(@doc[:params][0][:type]).to eq("string")
    end
    it "detects mixin param description" do
      expect(@doc[:params][0][:doc]).to eq("The name of the UI being created.")
    end
  end

  describe "CSS doc-comment followed by @mixin with parameters" do
    before do
      @doc = parse_member(<<-EOCSS)
        /**
         * Creates an awesome button.
         */
        @mixin my-button($foo, $bar: 2px) {
        }
      EOCSS
    end

    it "detects parameters" do
      expect(@doc[:params].length).to eq(2)
    end
    it "detects first param name" do
      expect(@doc[:params][0][:name]).to eq("$foo")
    end
    it "detects second param name" do
      expect(@doc[:params][1][:name]).to eq("$bar")
    end
    it "detects second param type" do
      expect(@doc[:params][1][:type]).to eq("number")
    end
    it "detects second param default value" do
      expect(@doc[:params][1][:default]).to eq("2px")
    end
  end

end
