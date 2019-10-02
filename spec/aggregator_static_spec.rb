require "mini_parser"

describe JsDuck::Aggregator do
  def parse(string)
    Helper::MiniParser.parse(string)
  end

  def parse_member(string)
    parse(string)["global"][:members][0]
  end

  describe "normal @static on single method" do
    before do
      @doc = parse_member(<<-EOS)
        /**
         * Some function
         * @static
         */
        function bar() {}
      EOS
    end

    it "labels that method as static" do
      expect(@doc[:static]).to eq(true)
    end

    it "doesn't detect inheritable property" do
      @doc[:inheritable].should_not == true
    end
  end

  describe "@static with @inheritable" do
    before do
      @doc = parse_member(<<-EOS)
        /**
         * Some function
         * @static
         * @inheritable
         */
        function bar() {}
      EOS
    end

    it "labels that method as static" do
      expect(@doc[:static]).to eq(true)
    end

    it "detects the @inheritable property" do
      expect(@doc[:inheritable]).to eq(true)
    end
  end

  describe "@static in class context" do
    before do
      @doc = parse(<<-EOS)["Foo"]
        /**
         * @class Foo
         */
        /**
         * Some function
         * @static
         */
        function bar() {}
        /**
         * Some property
         * @static
         */
        baz = "haha"
      EOS
    end

    it "adds static members to :members" do
      expect(@doc[:members].length).to eq(2)
    end
  end

  describe "Ext.define() with undocumented property in statics:" do
    let(:member) do
      parse(<<-EOS)["MyClass"][:members][0]
        /** @class Ext.Base */

        /**
         * Some documentation.
         */
        Ext.define("MyClass", {
            statics: {
                foo: 42
            }
        });
      EOS
    end

    describe "detects a member" do
      it "with :property tagname" do
        expect(member[:tagname]).to eq(:property)
      end

      it "with :static flag" do
        expect(member[:static]).to eq(true)
      end

      it "with :autodetected flag" do
        expect(member[:autodetected][:tagname]).to eq(:property)
      end

      it "with owner" do
        expect(member[:owner]).to eq("MyClass")
      end

      it "as private" do
        expect(member[:private]).to eq(true)
      end

      it "with :linenr field" do
        expect(member[:linenr]).to eq(8)
      end
    end
  end

  describe "Ext.define() with documented method in statics:" do
    let(:member) do
      parse(<<-EOS)["MyClass"][:members][0]
        /** @class Ext.Base */

        /**
         * Some documentation.
         */
        Ext.define("MyClass", {
            statics: {
                /** Docs for bar */
                bar: function() {}
            }
        });
      EOS
    end

    describe "detects a member" do
      it "with :method tagname" do
        expect(member[:tagname]).to eq(:method)
      end

      it "with :static flag" do
        expect(member[:static]).to eq(true)
      end

      it "with docs" do
        expect(member[:doc]).to eq("Docs for bar")
      end

      it "with owner" do
        expect(member[:owner]).to eq("MyClass")
      end

      it "as public" do
        member[:private].should_not == true
      end

      it "with :linenr field" do
        expect(member[:files][0][:linenr]).to eq(8)
      end
    end
  end

  describe "Ext.define() with undocumented method in inheritableStatics:" do
    let(:member) do
      parse(<<-EOS)["MyClass"][:members][0]
        /** @class Ext.Base */

        /**
         * Some documentation.
         */
        Ext.define("MyClass", {
            inheritableStatics: {
                bar: function() {}
            }
        });
      EOS
    end

    describe "detects a member" do
      it "with :method tagname" do
        expect(member[:tagname]).to eq(:method)
      end

      it "with :static flag" do
        expect(member[:static]).to eq(true)
      end

      it "with :inheritable flag" do
        expect(member[:inheritable]).to eq(true)
      end

      it "with :inheritdoc flag" do
        expect(member[:inheritdoc]).to eq({})
      end
    end
  end

  describe "Ext.define() with line-comment before item in statics:" do
    let(:member) do
      parse(<<-EOS)["MyClass"][:members][0]
        /** @class Ext.Base */

        /**
         * Some documentation.
         */
        Ext.define("MyClass", {
            statics: {
                // Check this out
                bar: function() {}
            }
        });
      EOS
    end

    it "detects a static" do
      expect(member[:static]).to eq(true)
    end

    it "detects a method" do
      expect(member[:tagname]).to eq(:method)
    end

    it "detects documentation" do
      expect(member[:doc]).to eq("Check this out")
    end

    it "detects the method with :autodetected flag" do
      expect(member[:autodetected][:tagname]).to eq(:method)
    end
  end

  describe "Ext.define() with property having value Ext.emptyFn in statics:" do
    let(:member) do
      parse(<<-EOS)["MyClass"][:members][0]
        /** @class Ext.Base */

        /**
         * Some documentation.
         */
        Ext.define("MyClass", {
            statics: {
                bar: Ext.emptyFn
            }
        });
      EOS
    end

    it "detects a static" do
      expect(member[:static]).to eq(true)
    end

    it "detects a method" do
      expect(member[:tagname]).to eq(:method)
    end
  end

end
