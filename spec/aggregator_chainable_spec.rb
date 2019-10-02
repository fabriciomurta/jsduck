require "mini_parser"

describe JsDuck::Aggregator do
  def parse(string)
    Helper::MiniParser.parse(string, {:return_values => true})
  end

  describe "both @return this and @chainable in method doc" do
    let(:cls) do
      parse(<<-EOS)["MyClass"]
        /** @class Ext.Base */

        /** */
        Ext.define("MyClass", {
            /**
             * @return {MyClass} this The instance itself.
             * @chainable
             */
            bar: function() {}
        });
      EOS
    end

    it "detects method as chainable" do
      expect(cls[:members][0][:chainable]).to eq(true)
    end

    it "keeps the original @return docs" do
      expect(cls[:members][0][:return][:doc]).to eq("this The instance itself.")
    end
  end

  describe "simple @chainable in method doc" do
    let(:cls) do
      parse(<<-EOS)["MyClass"]
        /** @class Ext.Base */

        /** */
        Ext.define("MyClass", {
            /**
             * @chainable
             */
            bar: function() {}
        });
      EOS
    end

    it "detects method as chainable" do
      expect(cls[:members][0][:chainable]).to eq(true)
    end

    it "adds @return {MyClass} this" do
      expect(cls[:members][0][:return][:type]).to eq("MyClass")
      expect(cls[:members][0][:return][:doc]).to eq("this")
    end
  end

  describe "an @return {MyClass} this in method doc" do
    let(:cls) do
      parse(<<-EOS)["MyClass"]
        /** @class Ext.Base */

        /** */
        Ext.define("MyClass", {
            /**
             * @return {MyClass} this
             */
            bar: function() {}
        });
      EOS
    end

    it "detects @return {MyClass} this" do
      expect(cls[:members][0][:return][:type]).to eq("MyClass")
      expect(cls[:members][0][:return][:doc]).to eq("this")
    end

    it "adds @chainable tag" do
      expect(cls[:members][0][:chainable]).to eq(true)
    end
  end

  describe "an @return {MyClass} this and other docs in method doc" do
    let(:cls) do
      parse(<<-EOS)["MyClass"]
        /** @class Ext.Base */

        /** */
        Ext.define("MyClass", {
            /**
             * @return {MyClass} this and some more...
             */
            bar: function() {}
        });
      EOS
    end

    it "detects @return {MyClass} this" do
      expect(cls[:members][0][:return][:type]).to eq("MyClass")
      expect(cls[:members][0][:return][:doc]).to eq("this and some more...")
    end

    it "adds @chainable tag" do
      expect(cls[:members][0][:chainable]).to eq(true)
    end
  end

  describe "an @return {MyClass} thisBlah in method doc" do
    let(:cls) do
      parse(<<-EOS)["MyClass"]
        /** @class Ext.Base */

        /** */
        Ext.define("MyClass", {
            /**
             * @return {MyClass} thisBlah
             */
            bar: function() {}
        });
      EOS
    end

    it "doesn't add @chainable tag" do
      cls[:members][0][:chainable].should_not == true
    end
  end

  describe "an @return {OtherClass} this in method doc" do
    let(:cls) do
      parse(<<-EOS)["MyClass"]
        /** @class Ext.Base */

        /** */
        Ext.define("MyClass", {
            /**
             * @return {OtherClass} this
             */
            bar: function() {}
        });
      EOS
    end

    it "doesn't add @chainable tag" do
      cls[:members][0][:chainable].should_not == true
    end
  end

  describe "an @return {MyClass} no-this in method doc" do
    let(:cls) do
      parse(<<-EOS)["MyClass"]
        /** @class Ext.Base */

        /** */
        Ext.define("MyClass", {
            /**
             * @return {MyClass}
             */
            bar: function() {}
        });
      EOS
    end

    it "doesn't add @chainable tag" do
      cls[:members][0][:chainable].should_not == true
    end
  end

  describe "method without any code" do
    let(:cls) do
      parse(<<-EOS)["MyClass"]
        /** @class Ext.Base */

        /** */
        Ext.define("MyClass", {
            /** @method bar */
        });
      EOS
    end

    it "doesn't add @chainable tag" do
      cls[:members][0][:chainable].should_not == true
    end
  end

  describe "method consisting of Ext.emptyFn in code" do
    let(:cls) do
      parse(<<-EOS)["MyClass"]
        /** @class Ext.Base */

        /** */
        Ext.define("MyClass", {
            /** */
            bar: Ext.emptyFn
        });
      EOS
    end

    it "doesn't add @chainable tag" do
      cls[:members][0][:chainable].should_not == true
    end
  end

  describe "function with 'return this;' in code" do
    let(:cls) do
      parse(<<-EOS)["MyClass"]
        /** @class Ext.Base */

        /** */
        Ext.define("MyClass", {
            /** */
            bar: function() { return this; }
        });
      EOS
    end

    it "adds @chainable tag" do
      expect(cls[:members][0][:chainable]).to eq(true)
    end

    it "marks :chainable field as autodetected" do
      expect(cls[:members][0][:autodetected][:chainable]).to eq(true)
    end

    it "adds @return {MyClass} this" do
      expect(cls[:members][0][:return][:type]).to eq("MyClass")
      expect(cls[:members][0][:return][:doc]).to eq("this")
    end
  end

  describe "constructor with no @return" do
    let(:cls) do
      parse(<<-EOS)["MyClass"]
        /** @class Ext.Base */

        /** */
        Ext.define("MyClass", {
            /** */
            constructor: function() {}
        });
      EOS
    end

    it "sets return type to owner class" do
      expect(cls[:members][0][:return][:type]).to eq("MyClass")
    end
  end

  describe "constructor with simple @return" do
    let(:cls) do
      parse(<<-EOS)["MyClass"]
        /** @class Ext.Base */

        /** */
        Ext.define("MyClass", {
            /**
             * @return new instance
             */
            constructor: function() {}
        });
      EOS
    end

    it "sets return type to owner class" do
      expect(cls[:members][0][:return][:type]).to eq("MyClass")
    end
  end

  describe "constructor with @constructor tag" do
    let(:cls) do
      parse(<<-EOS)["MyClass"]
        /** @class Ext.Base */

        /** */
        Ext.define("MyClass", {
            /**
             * @constructor
             */
            constructor: function() {}
        });
      EOS
    end

    it "sets return type to owner class" do
      expect(cls[:members][0][:return][:type]).to eq("MyClass")
    end
  end

  describe "constructor containing 'return this;'" do
    let(:cls) do
      parse(<<-EOS)["MyClass"]
        /** @class Ext.Base */

        /** */
        Ext.define("MyClass", {
            /** */
            constructor: function() {return this;}
        });
      EOS
    end

    it "doesn't get @chainable tag" do
      cls[:members][0][:chainable].should_not == true
    end
  end

  describe "constructor with some other explicit return type" do
    let(:cls) do
      parse(<<-EOS)["MyClass"]
        /** @class Ext.Base */

        /** */
        Ext.define("MyClass", {
            /** @return {OtherClass} new instance */
            constructor: function() {}
        });
      EOS
    end

    it "keeps the explicit return type" do
      expect(cls[:members][0][:return][:type]).to eq("OtherClass")
    end
  end

  describe "different implicit and explicit method names" do
    let(:cls) do
      parse(<<-EOS)["MyClass"]
        /** @class MyClass */
        /** @method foo */
        function bar() {
            return this;
        }
      EOS
    end

    it "doesn't detect chainable from code" do
      cls[:members][0][:chainable].should_not == true
    end
  end
end
