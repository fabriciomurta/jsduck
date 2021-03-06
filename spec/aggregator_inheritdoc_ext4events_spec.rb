require "mini_parser"

describe JsDuck::Aggregator do
  def parse(string)
    Helper::MiniParser.parse(string, {:ext4_events => true, :inherit_doc => true})
  end

  describe "@inheritdoc in Ext JS 4 event" do
    before do
      @docs = parse(<<-EOF)
        /** @class Ext.Base */

        /** */
        Ext.define("Foo", {
          /**
           * @event foo
           * Original comment.
           * @param arg1
           * @param arg2
           */
        });

        /** */
        Ext.define("Inh1", {
          /**
           * @event foo
           * @inheritdoc Foo#foo
           */
        });
      EOF
      @orig = @docs["Foo"][:members][0]
      @inh1 = @docs["Inh1"][:members][0]
    end

    it "generates 3rd param to original event" do
      expect(@orig[:params].length).to eq(3)
    end

    it "inherits all three parameters" do
      expect(@inh1[:params].length).to eq(3)
    end

  end

end
