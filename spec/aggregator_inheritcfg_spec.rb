require "mini_parser"

describe JsDuck::Aggregator do
  def parse(string)
    Helper::MiniParser.parse(string, {:inherit_doc => true})
  end

  describe "auto-detected property overriding property in parent" do
    let(:classes) do
      parse(<<-EOS)
        /** @class Ext.Base */

        /** */
        Ext.define("Parent", {
            /** @property */
            blah: 7
        });

        /** */
        Ext.define("Child", {
            extend: "Parent",
            blah: 8
        });
      EOS
    end

    it "detects a property in parent" do
      expect(classes["Parent"][:members][0][:tagname]).to eq(:property)
    end

    it "detects a property in child" do
      expect(classes["Child"][:members][0][:tagname]).to eq(:property)
    end

    it "detects property in child as public" do
      expect(classes["Child"][:members][0][:private]).not_to eq(true)
    end
  end

  describe "auto-detected property overriding config in parent" do
    let(:classes) do
      parse(<<-EOS)
        /** @class Ext.Base */

        /** */
        Ext.define("Parent", {
            /** @cfg */
            blah: 7
        });

        /** */
        Ext.define("Child", {
            extend: "Parent",
            blah: 8
        });
      EOS
    end

    it "detects a config in parent" do
      expect(classes["Parent"][:members][0][:tagname]).to eq(:cfg)
    end

    it "detects a config in child" do
      expect(classes["Child"][:members][0][:tagname]).to eq(:cfg)
    end

    it "detects the child config with correct tagname" do
      classes["Child"][:members][0][:tagname] == :cfg
    end

    it "detects the child config with correct id" do
      classes["Child"][:members][0][:id] == "cfg-blah"
    end

    it "detects no properties in child" do
      expect(classes["Child"][:members].length).to eq(1)
    end
  end

  describe "auto-detected property overriding config in grandparent" do
    let(:classes) do
      # The classes are ordered from child to excercise the code that
      # ensure we inherit parent docs before inheriting the child docs
      # from it.
      parse(<<-EOS)
        /** @class Ext.Base */

        /** */
        Ext.define("Child", {
            extend: "Parent",
            blah: 8
        });

        /** */
        Ext.define("Parent", {
            extend: "GrandParent",
            blah: 7
        });

        /** */
        Ext.define("GrandParent", {
            /** @cfg */
            blah: 7
        });
      EOS
    end

    it "detects a config in child" do
      expect(classes["Child"][:members][0][:tagname]).to eq(:cfg)
    end

    it "detects a config in parent" do
      expect(classes["Parent"][:members][0][:tagname]).to eq(:cfg)
    end
  end

end
