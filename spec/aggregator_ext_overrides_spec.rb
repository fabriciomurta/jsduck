require "mini_parser"

describe JsDuck::Aggregator do
  def parse(string)
    Helper::MiniParser.parse(string, {:overrides => true, :filename => "blah.js"})
  end

  def create_members_map(cls)
    r = {}
    cls.all_local_members.each do |m|
      r[m[:name]] = m
    end
    r
  end

  describe "defining @override for a class" do
    let(:classes) do
      parse(<<-EOF)
        /**
         * @class Foo
         * Foo comment.
         */
          /**
           * @method foo
           * Foo comment.
           */
          /**
           * @method foobar
           * Original comment.
           */

        /**
         * @class FooOverride
         * @override Foo
         * FooOverride comment.
         */
          /**
           * @method bar
           * Bar comment.
           */
          /**
           * @method foobar
           * Override comment.
           */
      EOF
    end

    let(:methods) { create_members_map(classes["Foo"]) }

    it "keeps the original class" do
      expect(classes["Foo"]).not_to eq(nil)
    end

    it "throws away the override" do
      expect(classes["FooOverride"]).to eq(nil)
    end

    it "places the override into ignored classes list" do
      expect(classes.ignore?("FooOverride")).to eq(true)
    end

    it "combines class doc with doc from override" do
      expect(classes["Foo"][:doc]).to eq("Foo comment.\n\n**From override FooOverride:** FooOverride comment.")
    end

    it "adds override to list of source files" do
      expect(classes["Foo"][:files].length).to eq(2)
    end

    it "keeps its original foo method" do
      expect(methods["foo"]).not_to eq(nil)
    end

    it "gets the new bar method from override" do
      expect(methods["bar"]).not_to eq(nil)
    end

    it "adds special override comment to bar method" do
      expect(methods["bar"][:doc]).to eq("Bar comment.\n\n**Defined in override FooOverride.**")
    end

    it "changes owner of bar method to target class" do
      expect(methods["bar"][:owner]).to eq("Foo")
    end

    it "keeps the foobar method that's in both original and override" do
      expect(methods["foobar"]).not_to eq(nil)
    end

    it "combines docs of original and override" do
      expect(methods["foobar"][:doc]).to eq("Original comment.\n\n**From override FooOverride:** Override comment.")
    end

    it "adds override source to list of files to overridden member" do
      expect(methods["foobar"][:files].length).to eq(2)
    end

    it "keeps owner of foobar method to be the original class" do
      expect(methods["foobar"][:owner]).to eq("Foo")
    end
  end

  describe "comment-less @override for a class" do
    let(:classes) do
      parse(<<-EOF)
        /**
         * @class Foo
         * Foo comment.
         */
          /**
           * @method foobar
           * Original comment.
           */

        /**
         * @class FooOverride
         * @override Foo
         */
          /**
           * @method foobar
           */
      EOF
    end

    let(:methods) { create_members_map(classes["Foo"]) }

    it "adds no doc from override to the class itself" do
      expect(classes["Foo"][:doc]).to eq("Foo comment.")
    end

    it "adds note about override to member" do
      expect(methods["foobar"][:doc]).to eq("Original comment.\n\n**Overridden in FooOverride.**")
    end
  end

  describe "auto-detected override: in Ext.define" do
    let(:classes) do
      parse(<<-EOF)
        /** @class Ext.Base */

        /** */
        Ext.define("Foo", {
            foobar: function(){}
        });

        /** */
        Ext.define("FooOverride", {
            override: "Foo",
            bar: function(){},
            foobar: function(){ return true; }
        });
      EOF
    end

    let(:methods) { create_members_map(classes["Foo"]) }

    it "adds member to overridden class" do
      expect(methods["bar"]).not_to eq(nil)
    end

    it "adds note to docs about member being overridden" do
      expect(methods["foobar"][:doc]).to eq("**Overridden in FooOverride.**")
    end
  end

  describe "use of @override tag without @class" do
    let(:classes) do
      parse(<<-EOF)
        /** @class Ext.Base */

        /** */
        Ext.define("Foo", {
            foobar: function(){}
        });

        /** @override Foo */
        Ext.apply(Foo.prototype, {
            /** */
            bar: function(){ },
            /** */
            foobar: function(){ return true; }
        });
      EOF
    end

    let(:methods) { create_members_map(classes["Foo"]) }

    it "adds member to overridden class" do
      expect(methods["bar"]).not_to eq(nil)
    end

    it "adds note to docs about member being overridden" do
      expect(methods["foobar"][:doc]).to eq("**Overridden in blah.js.**")
    end
  end

  describe "override created with Ext.override" do
    let(:classes) do
      parse(<<-EOF)
        /** @class Ext.Base */

        /** */
        Ext.define("Foo", {
            foobar: function(){}
        });

        /** */
        Ext.override(Foo, {
            bar: function(){ },
            foobar: function(){ return true; }
        });
      EOF
    end

    let(:methods) { create_members_map(classes["Foo"]) }

    it "adds member to overridden class" do
      expect(methods["bar"]).not_to eq(nil)
    end

    it "adds note to docs about member being overridden" do
      expect(methods["foobar"][:doc]).to eq("**Overridden in blah.js.**")
    end
  end

  describe "@override without classname" do
    let(:classes) do
      parse(<<-EOF)
        /** @class Ext.Base */

        /** */
        Ext.define("Foo", {
            /** @override */
            foo: function() { }
        });
      EOF
    end

    let(:methods) { create_members_map(classes["Foo"]) }

    it "gets ignored" do
      expect(methods["foo"]).not_to eq(nil)
    end
  end
end
