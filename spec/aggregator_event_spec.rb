require "mini_parser"

describe JsDuck::Aggregator do

  def parse(string)
    Helper::MiniParser.parse(string)
  end

  def parse_member(string)
    parse(string)["global"][:members][0]
  end

  shared_examples_for "event" do
    it "creates event" do
      expect(@doc[:tagname]).to eq(:event)
    end

    it "takes documentation from doc-comment" do
      expect(@doc[:doc]).to eq("Fires when needed.")
    end

    it "detects event name" do
      expect(@doc[:name]).to eq("mousedown")
    end
  end

  describe "explicit event" do
    before do
      @doc = parse_member(<<-EOS)
        /**
         * @event mousedown
         * Fires when needed.
         */
      EOS
    end
    it_should_behave_like "event"
  end

  describe "event with @event after @params" do
    before do
      @doc = parse_member(<<-EOS)
        /**
         * Fires when needed.
         * @param {String} x First parameter
         * @param {Number} y Second parameter
         * @event mousedown
         */
      EOS
    end
    it_should_behave_like "event"
  end

  describe "implicit event name as string" do
    before do
      @doc = parse_member(<<-EOS)
        /**
         * @event
         * Fires when needed.
         */
        "mousedown"
      EOS
    end
    it_should_behave_like "event"
  end

  describe "implicit event name as object property" do
    before do
      @doc = parse_member(<<-EOS)
      ({/**
         * @event
         * Fires when needed.
         */
        mousedown: true })
      EOS
    end
    it_should_behave_like "event"
  end

  describe "implicit event name inside this.fireEvent()" do
    before do
      @doc = parse_member(<<-EOS)
        /**
         * Fires when needed.
         */
        this.fireEvent("mousedown", foo, 7);
      EOS
    end
    it_should_behave_like "event"
  end

  describe "doc-comment followed by this.fireEvent without event name" do
    before do
      @doc = parse_member(<<-EOS)
        /**
         * Fires when needed.
         */
        this.fireEvent(foo, 7);
      EOS
    end

    it "creates event" do
      expect(@doc[:tagname]).to eq(:event)
    end

    it "leaves the name of event empty" do
      expect(@doc[:name]).to eq("")
    end
  end

end
