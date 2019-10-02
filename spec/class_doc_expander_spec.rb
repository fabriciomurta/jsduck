require "jsduck/class_doc_expander"
require "mini_parser"

describe JsDuck::ClassDocExpander do
  def parse(string)
    Helper::MiniParser.parse(string)
  end

  describe "class with cfgs" do
    let(:cls) do
      parse(<<-EOS)["MyClass"]
        /** @class Bar */

        /**
         * @class MyClass
         * @extends Bar
         * Comment here.
         * @cfg {String} foo Hahaha
         * @private
         * @cfg {Boolean} bar Hihihi
         */
      EOS
    end

    it "has needed number of members" do
      expect(cls[:members].length).to eq(2)
    end
    it "detects members as configs" do
      expect(cls[:members][0][:tagname]).to eq(:cfg)
      expect(cls[:members][1][:tagname]).to eq(:cfg)
    end
    it "picks up names of all configs" do
      expect(cls[:members][0][:name]).to eq("foo")
      expect(cls[:members][1][:name]).to eq("bar")
    end
    it "marks first @cfg as private" do
      expect(cls[:members][0][:private]).to eq(true)
    end
  end

  describe "class with cfgs with subproperties" do
    let(:cls) do
      parse(<<-EOS)["MyClass"]
        /**
         * @class MyClass
         * Comment here.
         * @cfg {Object} foo
         * @cfg {String} foo.one
         * @cfg {String} foo.two
         * @cfg {Function} bar
         * @cfg {Boolean} bar.arg
         */
      EOS
    end

    it "detects the configs taking account the subproperties" do
      expect(cls[:members].length).to eq(2)
    end
  end

  describe "class with parentless sub-cfg" do
    let(:cls) do
      parse(<<-EOS)["MyClass"]
        /**
         * @class MyClass
         * Comment here.
         * @cfg {String} foo.one
         */
      EOS
    end

    it "detects the one bogus config" do
      expect(cls[:members].length).to eq(1)
    end
  end

  describe "implicit class with more than one cfg" do
    let(:cls) do
      parse(<<-EOS)["MyClass"]
        /**
         * Comment here.
         * @cfg {String} foo
         * @cfg {String} bar
         */
        MyClass = function() {}
      EOS
    end

    it "is detected as class" do
      expect(cls[:tagname]).to eq(:class)
    end
  end

  describe "configs in class doc-comment and separately" do
    let(:cls) do
      parse(<<-EOS)["Foo"]
        /**
         * @class Foo
         * @cfg c1
         */
          /** @cfg c2 */
          /** @cfg c3 */
      EOS
    end

    it "get all combined into one members list" do
      expect(cls[:members].length).to eq(3)
    end
  end

end
