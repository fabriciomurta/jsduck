require "mini_parser"

describe JsDuck::Aggregator do

  def parse(string)
    Helper::MiniParser.parse(string)
  end

  describe "@member defines the class of member" do

    it "when inside a lonely doc-comment" do
      classes = parse(<<-EOS)
        /**
         * @cfg foo
         * @member Bar
         */
      EOS
      expect(classes["Bar"][:members][0][:owner]).to eq("Bar")
    end

    it "when used after the corresponding @class" do
      classes = parse(<<-EOS)
        /**
         * @class Bar
         */
        /**
         * @class Baz
         */
        /**
         * @cfg foo
         * @member Bar
         */
      EOS
      expect(classes["Bar"][:members].length).to eq(1)
      expect(classes["Baz"][:members].length).to eq(0)
    end

    it "when used before the corresponding @class" do
      classes = parse(<<-EOS)
        /**
         * @cfg foo
         * @member Bar
         */
        /**
         * @class Bar
         */
      EOS
      expect(classes["Bar"][:members].length).to eq(1)
    end
  end

  it "creates classes for all orphans with @member defined" do
    classes = parse(<<-EOS)
      /**
       * @cfg foo
       * @member FooCls
       */
      /**
       * @cfg bar
       * @member BarCls
       */
    EOS

    expect(classes["FooCls"][:members].length).to eq(1)
    expect(classes["BarCls"][:members].length).to eq(1)
  end

end
