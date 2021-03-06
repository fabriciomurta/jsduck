require "mini_parser"

describe JsDuck::Aggregator do
  def parse(string)
    Helper::MiniParser.parse(string, {:ext4_events => true})
  end

  describe "event inside Ext.define get extra parameter" do
    let(:event) do
      parse(<<-EOF)["Blah"][:members][0]
        /** @class Ext.Base */

        /** */
        Ext.define("Blah", {
            /**
             * @event click
             * @param {Number} foo
             * @param {String} bar
             */
        });
      EOF
    end

    it "added to end" do
      expect(event[:params].length).to eq(3)
    end

    it "named eOpts" do
      expect(event[:params][2][:name]).to eq("eOpts")
    end

    it "of type Object" do
      expect(event[:params][2][:type]).to eq("Object")
    end

    it "with standard description" do
      expect(event[:params][2][:doc]).to match(/The options object passed to.*addListener/)
    end

    it "with special :ext4event flag" do
      expect(event[:params][2][:ext4_auto_param]).to eq(true)
    end
  end

  describe "When some class defined with Ext.define" do
    let(:events) do
      parse(<<-EOF)["Foo"][:members]
        /** @class Ext.Base */

        /** @class Foo */
            /**
             * @event click
             * @param {Number} foo
             */
            /**
             * @event touch
             */

        /** */
        Ext.define("Bar", {});
      EOF
    end

    it "events get extra parameter" do
      expect(events[0][:params].length).to eq(2)
      expect(events[1][:params].length).to eq(1)
    end
  end

  describe "Without Ext.define-d class" do
    let(:events) do
      parse(<<-EOF)["Foo"][:members]
        /** @class Foo */
            /**
             * @event click
             * @param {Number} foo
             */
            /**
             * @event touch
             */
      EOF
    end

    it "no extra param gets added" do
      expect(events[0][:params].length).to eq(1)
      expect(events[1][:params].length).to eq(0)
    end
  end

end
