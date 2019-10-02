require "mini_parser"

describe JsDuck::Aggregator do

  def parse(string)
    Helper::MiniParser.parse(string, {:ignored_classes => true})
  end

  describe "@ignore in member" do
    before do
      @docs = parse(<<-EOSTR)["Foo"]
      /**
       * @class Foo
       */
          /**
           * @method bar
           * @ignore
           */
      EOSTR
    end

    it "ignores the member completely" do
      expect(@docs[:members].length).to eq(0)
    end
  end

  describe "@ignore in class" do
    before do
      @docs = parse(<<-EOSTR)
      /**
       * @class Foo
       * @ignore
       */
          /**
           * @method bar
           */
          /**
           * @method baz
           */
      EOSTR
    end

    it "ignores the class and all it's members" do
      expect(@docs.length).to eq(0)
    end
  end

  describe "@ignore in duplicate member" do
    before do
      @doc = parse(<<-EOSTR)["Foo"]
      /**
       * @class Foo
       */
          /**
           * @method bar
           * First method docs
           */
          /**
           * @method bar
           * Second method docs
           * @ignore
           */
      EOSTR
    end

    it "ignores one member" do
      expect(@doc[:members].length).to eq(1)
    end

    it "lets the other member stay" do
      expect(@doc[:members][0][:doc]).to eq("First method docs")
    end
  end

end
