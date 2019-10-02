require "jsduck/js/ast"
require "jsduck/js/parser"

describe "JsDuck::Js::Ast detects class with" do
  def detect(string)
    node = JsDuck::Js::Parser.new(string).parse[0]
    return JsDuck::Js::Ast.new.detect(node[:code])
  end

  describe "name in" do
    it "function declaration" do
      expect(detect("/** */ function MyClass() {}")[:name]).to eq("MyClass")
    end

    it "function assignment" do
      expect(detect("/** */ MyClass = function() {}")[:name]).to eq("MyClass")
    end

    it "function assignment to property" do
      expect(detect("/** */ foo.MyClass = function() {}")[:name]).to eq("foo.MyClass")
    end

    it "var initialization with function" do
      expect(detect("/** */ var MyClass = function() {}")[:name]).to eq("MyClass")
    end

    it "Ext.extend() assignment" do
      expect(detect("/** */ MyClass = Ext.extend(Your.Class, {  });")[:name]).to eq("MyClass")
    end

    it "var initialized with Ext.extend()" do
      expect(detect("/** */ var MyClass = Ext.extend(Your.Class, {  });")[:name]).to eq("MyClass")
    end

    it "Ext.define() with object literal" do
      expect(detect(<<-EOS)[:name]).to eq("MyClass")
        /** */
        Ext.define('MyClass', {
        });
      EOS
    end

    it "Ext.define() with function" do
      expect(detect(<<-EOS)[:name]).to eq("MyClass")
        /** */
        Ext.define('MyClass', function() {});
      EOS
    end
  end

  describe "extends in" do
    it "Ext.extend() assignment" do
      expect(detect("/** */ MyClass = Ext.extend(Your.Class, {  });")[:extends]).to eq("Your.Class")
    end

    it "var initialized with Ext.extend()" do
      expect(detect("/** */ var MyClass = Ext.extend(Your.Class, {  });")[:extends]).to eq("Your.Class")
    end

    it "Ext.define() with extend:" do
      expect(detect(<<-EOS)[:extends]).to eq("Your.Class")
        /** */
        Ext.define('MyClass', {
            extend: "Your.Class"
        });
      EOS
    end

    it "Ext.define() with extend: as second object property" do
      expect(detect(<<-EOS)[:extends]).to eq("Your.Class")
        /** */
        Ext.define('MyClass', {
            foo: 5,
            extend: "Your.Class"
        });
      EOS
    end

    it "Ext.define() with function argument" do
      expect(detect(<<-EOS)[:extends]).to eq("Ext.Base")
        /** */
        Ext.define('MyClass', function() {
        });
      EOS
    end

    it "Ext.define() with function returning object" do
      expect(detect(<<-EOS)[:extends]).to eq("Your.Class")
        /** */
        Ext.define('MyClass', function() {
            return {extend: "Your.Class"};
        });
      EOS
    end

    # TODO: Doesn't work at the moment
    #
    # it "Ext.define() with function returning two possible objects" do
    #   expect(detect(<<-EOS)[:extends]).to eq("Ext.Base")
    #     /** */
    #     Ext.define('MyClass', function() {
    #         if (someCondition) {
    #             return {extend: "Your.Class1"};
    #         }
    #         return {extend: "Your.Class2"};
    #     });
    #   EOS
    # end

    it "Ext.define() with no extend: in config object" do
      expect(detect(<<-EOS)[:extends]).to eq("Ext.Base")
        /** */
        Ext.define('MyClass', {
            foo: 5,
            bar: "hah"
        });
      EOS
    end
  end

  describe "no extends in" do
    it "plain variable assignment" do
      expect(detect(<<-EOS)[:extends]).to eq(nil)
        /** */
        MyClass = {
            extend: 5
        };
      EOS
    end
  end

  describe "requires in" do
    it "Ext.define() with requires as string" do
      expect(detect(<<-EOS)[:requires]).to eq(["Other.Class"])
        /** */
        Ext.define('MyClass', {
            requires: "Other.Class"
        });
      EOS
    end

    it "Ext.define() with requires as array of strings" do
      expect(detect(<<-EOS)[:requires]).to eq(["Some.Class", "Other.Class"])
        /** */
        Ext.define('MyClass', {
            requires: ["Some.Class", "Other.Class"]
        });
      EOS
    end
  end

  describe "no requires in" do
    it "Ext.define() without requires" do
      expect(detect(<<-EOS)[:requires]).to eq([])
        /** */
        Ext.define('MyClass', {
        });
      EOS
    end

    it "Ext.define() with requires as array of functions and strings" do
      expect(detect(<<-EOS)[:requires]).to eq([])
        /** */
        Ext.define('MyClass', {
            requires: [function(){}, "Foo"]
        });
      EOS
    end

    it "Ext.define() with requires as nested array" do
      expect(detect(<<-EOS)[:requires]).to eq([])
        /** */
        Ext.define('MyClass', {
            requires: ["Foo", ["Bar"]]
        });
      EOS
    end
  end

  describe "uses in" do
    # Just a smoke-test here, as it's sharing the implementation of :requires
    it "Ext.define() with uses as array" do
      expect(detect(<<-EOS)[:uses]).to eq(["Other.Class"])
        /** */
        Ext.define('MyClass', {
            uses: ["Other.Class"]
        });
      EOS
    end
  end

  describe "alternateClassNames in" do
    # Just a smoke-test here, as it's sharing the implementation of :requires
    it "Ext.define() with alternateClassName as string" do
      expect(detect(<<-EOS)[:alternateClassNames]).to eq(["Other.Class"])
        /** */
        Ext.define('MyClass', {
            alternateClassName: "Other.Class"
        });
      EOS
    end
  end

  describe "mixins in" do
    it "Ext.define() with mixins as string" do
      expect(Set.new(detect(<<-EOS)[:mixins])).to eq(Set.new(["Some.Class", "Other.Class"]))
        /** */
        Ext.define('MyClass', {
            mixins: ["Some.Class", "Other.Class"]
        });
      EOS
    end

    it "Ext.define() with mixins as array of strings" do
      expect(Set.new(detect(<<-EOS)[:mixins])).to eq(Set.new(["Other.Class"]))
        /** */
        Ext.define('MyClass', {
            mixins: "Other.Class"
        });
      EOS
    end

    it "Ext.define() with mixins as object" do
      expect(Set.new(detect(<<-EOS)[:mixins])).to eq(Set.new(["Some.Class", "Other.Class"]))
        /** */
        Ext.define('MyClass', {
            mixins: {
                some: "Some.Class",
                other: "Other.Class"
            }
        });
      EOS
    end
  end

  describe "no mixins in" do
    it "Ext.define() without mixins" do
      expect(detect(<<-EOS)[:mixins]).to eq([])
        /** */
        Ext.define('MyClass', {
        });
      EOS
    end

    it "Ext.define() with mixins as nested object" do
      expect(detect(<<-EOS)[:mixins]).to eq([])
        /** */
        Ext.define('MyClass', {
            mixins: {foo: {bar: "foo"}}
        });
      EOS
    end

    it "Ext.define() with mixins as identifier" do
      expect(detect(<<-EOS)[:mixins]).to eq([])
        /** */
        Ext.define('MyClass', {
            mixins: someVar
        });
      EOS
    end
  end

  describe "singleton in" do
    it "Ext.define() with singleton:true" do
      expect(detect(<<-EOS)[:singleton]).to eq(true)
        /** */
        Ext.define('MyClass', {
            singleton: true
        });
      EOS
    end
  end

  describe "no singleton in" do
    it "Ext.define() with singleton:false" do
      expect(detect(<<-EOS)[:singleton]).not_to eq(true)
        /** */
        Ext.define('MyClass', {
            singleton: false
        });
      EOS
    end

    it "Ext.define() without singleton" do
      expect(detect(<<-EOS)[:singleton]).not_to eq(true)
        /** */
        Ext.define('MyClass', {
        });
      EOS
    end
  end

  describe "aliases in" do
    it "Ext.define() single string alias" do
      expect(detect(<<-EOS)[:aliases]).to eq(["widget.foo"])
        /** */
        Ext.define('MyClass', {
            alias: "widget.foo"
        });
      EOS
    end

    it "Ext.define() with alias as array" do
      expect(detect(<<-EOS)[:aliases]).to eq(["widget.foo", "widget.fooeditor"])
        /** */
        Ext.define('MyClass', {
            alias: ["widget.foo", "widget.fooeditor"]
        });
      EOS
    end

    it "Ext.define() with xtype" do
      expect(detect(<<-EOS)[:aliases]).to eq(["widget.foo"])
        /** */
        Ext.define('MyClass', {
            xtype: "foo"
        });
      EOS
    end

    it "Ext.define() with alias and xtype" do
      expect(detect(<<-EOS)[:aliases]).to eq(["widget.foo", "widget.fooeditor"])
        /** */
        Ext.define('MyClass', {
            alias: "widget.foo",
            xtype: "fooeditor"
        });
      EOS
    end
  end

end
