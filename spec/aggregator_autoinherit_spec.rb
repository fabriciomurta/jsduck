require "mini_parser"

describe JsDuck::Aggregator do
  def parse(string)
    Helper::MiniParser.parse(string, {:inherit_doc => true})
  end

  describe "autoinherit with config:{}" do
    before do
      @docs = parse(<<-EOF)
        /** @class Ext.Base */

        /** */
        Ext.define("Parent", {
            config: {
                /**
                 * My config.
                 */
                foo: 5
            }
        });
        /** */
        Ext.define("Child", {
            extend: "Parent",
            config: {
                foo: 10
            }
        });
      EOF
      @cls = @docs["Child"]
      @cfg = @cls[:members][0]
    end

    it "inherits docs from parent" do
      expect(@cfg[:doc]).to eq("My config.")
    end

    it "inherits being public from parent" do
      expect(@cfg[:private]).to eq(nil)
    end
  end

  describe "autoinherit with config:{} through two parents" do
    before do
      @docs = parse(<<-EOF)
        /** @class Ext.Base */

        /** */
        Ext.define("Parent", {
            config: {
                /**
                 * My config.
                 */
                foo: 5
            }
        });
        /** */
        Ext.define("Middle", {
            extend: "Parent",
            config: {
                foo: 7
            }
        });
        /** */
        Ext.define("Child", {
            extend: "Middle",
            config: {
                foo: 10
            }
        });
      EOF
      @cls = @docs["Child"]
      @cfg = @cls[:members][0]
    end

    it "inherits docs from parent" do
      expect(@cfg[:doc]).to eq("My config.")
    end

    it "inherits being public from parent" do
      expect(@cfg[:private]).to eq(nil)
    end
  end

  describe "autoinherit with config:{} and no parent" do
    before do
      @docs = parse(<<-EOF)
        /** @class Ext.Base */

        /** */
        Ext.define("Child", {
            config: {
                foo: 10
            }
        });
      EOF
      @cls = @docs["Child"]
      @cfg = @cls[:members][0]
    end

    it "becomes private" do
      expect(@cfg[:private]).to eq(true)
    end
  end

  describe "autoinherit with several tags" do
    before do
      @docs = parse(<<-EOF)
        /** @class Ext.Base */

        /** */
        Ext.define("Parent", {
            /**
             * My property.
             * @protected
             * @deprecated 4.0 Use something else.
             * @readonly
             */
            foo: 5
        });
        /** */
        Ext.define("Child", {
            extend: "Parent",
            foo: 10
        });
      EOF
      @cls = @docs["Child"]
      @property = @cls[:members][0]
    end

    it "inherits @protected" do
      expect(@property[:protected]).to eq(true)
    end

    it "inherits @deprecated" do
      expect(@property[:deprecated][:version]).to eq("4.0")
      expect(@property[:deprecated][:text]).to eq("Use something else.")
    end

    it "inherits @readonly" do
      expect(@property[:readonly]).to eq(true)
    end
  end

  describe "autoinherit with his own and parent tags" do
    before do
      @docs = parse(<<-EOF)
        /** @class Ext.Base */

        /** */
        Ext.define("Parent", {
            /**
             * My property.
             * @protected
             * @deprecated 3.0
             */
            foo: 5
        });
        /** */
        Ext.define("Child", {
            extend: "Parent",
            // @readonly
            // @deprecated 4.0
            foo: 10
        });
      EOF
      @cls = @docs["Child"]
      @property = @cls[:members][0]
    end

    it "inherits @protected" do
      expect(@property[:protected]).to eq(true)
    end

    it "keeps @readonly" do
      expect(@property[:readonly]).to eq(true)
    end

    it "keeps default value" do
      expect(@property[:default]).to eq("10")
    end

    it "overrides @deprecated of parent with its own @deprecated" do
      expect(@property[:deprecated][:version]).to eq("4.0")
    end
  end

  describe "inheriting cfg/property type" do
    let(:members) do
      ms = parse(<<-EOF)["Child"][:members]
        /** @class Ext.Base */

        /** */
        Ext.define("Parent", {
            /**
             * @property {String/Number}
             */
            foo: 42,
            /**
             * @property {String/Number}
             */
            bar: 5,
            baz: 15,
            /**
             * @property {String/Number}
             * @private
             */
            zap: 7
        });
        /** */
        Ext.define("Child", {
            extend: "Parent",
            /**
             * @inheritdoc
             */
            foo: "blah",
            bar: "blah",
            baz: "blah",
            zap: "blah"
        });
      EOF
      hash = {}
      ms.each {|p| hash[p[:name]] = p }
      hash
    end

    it "explicit inherit from public parent keeps the type of parent" do
      expect(members["foo"][:type]).to eq("String/Number")
    end

    it "autoinherit from public parent keeps the type of parent" do
      expect(members["bar"][:type]).to eq("String/Number")
    end

    it "autoinherit from private parent overrides parent type" do
      expect(members["baz"][:type]).to eq("String")
    end

    it "autoinherit from explicitly documented private parent keeps parent type" do
      expect(members["zap"][:type]).to eq("String/Number")
    end
  end

  describe "instance members autoinherit with parent containing statics" do
    before do
      @docs = parse(<<-EOF)
        /** @class Ext.Base */

        /** */
        Ext.define("Parent", {
            inheritableStatics: {
                /** My method. */
                foo: function() {},
                /** My property. */
                bar: 10
            }
        });
        /** */
        Ext.define("Child", {
            extend: "Parent",
            foo: function(){},
            bar: 11
        });
      EOF
      @cls = @docs["Child"]
    end

    it "doesn't inherit from parent static method" do
      @cls[:members][0][:doc].should_not == "My method."
    end

    it "doesn't inherit from parent static property" do
      @cls[:members][1][:doc].should_not == "My property."
    end
  end

  describe "static members autoinherit with parent containing statics" do
    before do
      @docs = parse(<<-EOF)
        /** @class Ext.Base */

        /** */
        Ext.define("Parent", {
            inheritableStatics: {
                /** My method. */
                foo: function() {},
                /** My property. */
                bar: 10
            }
        });
        /** */
        Ext.define("Child", {
            extend: "Parent",
            inheritableStatics: {
                foo: function(){},
                bar: 11
            }
        });
      EOF
      @cls = @docs["Child"]
    end

    it "inherits from parent static method" do
      expect(@cls[:members][0][:doc]).to eq("My method.")
    end

    it "inherits from parent static property" do
      expect(@cls[:members][1][:doc]).to eq("My property.")
    end
  end
end
