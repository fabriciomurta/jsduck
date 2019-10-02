require "mini_parser"

describe JsDuck::Aggregator do
  def parse(string)
    Helper::MiniParser.parse(string)
  end

  shared_examples_for "class" do
    it "creates class" do
      expect(@doc[:tagname]).to eq(:class)
    end
    it "detects name" do
      expect(@doc[:name]).to eq("MyClass")
    end
  end

  describe "explicit class" do
    before do
      @doc = parse(<<-EOS)["MyClass"]
       /**
         * @class Your.Class
         * Some docs
         */

       /**
         * @class Foo.Mixin
         * Some docs
         */

       /**
         * @class Bar.Mixin
         * Some docs
         */

       /**
         * @class MyClass
         * @extends Your.Class
         * @mixins Foo.Mixin Bar.Mixin
         * @alternateClassNames AltClass
         * Some documentation.
         * @singleton
         */
      EOS
    end

    it_should_behave_like "class"
    it "detects extends" do
      expect(@doc[:extends]).to eq("Your.Class")
    end
    it "detects mixins" do
      expect(Set.new(@doc[:mixins])).to eq(Set.new(["Foo.Mixin", "Bar.Mixin"]))
    end
    it "detects alternate class names" do
      expect(@doc[:alternateClassNames]).to eq(["AltClass"])
    end
    it "takes documentation from doc-comment" do
      expect(@doc[:doc]).to eq("Some documentation.")
    end
    it "detects singleton" do
      expect(@doc[:singleton]).to eq(true)
    end
  end

  describe "class @tag aliases" do
    before do
      @doc = parse(<<-EOS)["MyClass"]
       /**
         * @class Your.Class
         * Some docs
         */

       /**
         * @class My.Mixin
         * Some docs
         */

        /**
         * @class MyClass
         * @extend Your.Class
         * @mixin My.Mixin
         * @alternateClassName AltClass
         * Some documentation.
         */
      EOS
    end

    it_should_behave_like "class"
    it "@extend treated as alias for @extends" do
      expect(@doc[:extends]).to eq("Your.Class")
    end
    it "@mixin treated as alias for @mixins" do
      expect(@doc[:mixins]).to eq(["My.Mixin"])
    end
    it "@alternateClassName treated as alias for @alternateClassNames" do
      expect(@doc[:alternateClassNames]).to eq(["AltClass"])
    end
  end

  describe "class with multiple @mixins" do
    before do
      @doc = parse(<<-EOS)["MyClass"]
       /**
         * @class My.Mixin
         * Some docs
         */

       /**
         * @class Your.Mixin
         * Some docs
         */

       /**
         * @class Other.Mixin
         * Some docs
         */

        /**
         * @class MyClass
         * @mixins My.Mixin
         * @mixins Your.Mixin Other.Mixin
         * Some documentation.
         */
      EOS
    end

    it_should_behave_like "class"
    it "collects all mixins together" do
      expect(Set.new(@doc[:mixins])).to eq(Set.new(["My.Mixin", "Your.Mixin", "Other.Mixin"]))
    end
  end

  describe "class with multiple @alternateClassNames" do
    before do
      @doc = parse(<<-EOS)["MyClass"]
        /**
         * @class MyClass
         * @alternateClassNames AltClass1
         * @alternateClassNames AltClass2
         * Some documentation.
         */
      EOS
    end

    it_should_behave_like "class"
    it "collects all alternateClassNames together" do
      expect(@doc[:alternateClassNames]).to eq(["AltClass1", "AltClass2"])
    end
  end

  describe "function after doc-comment" do
    before do
      @doc = parse("/** */ function MyClass() {}")["MyClass"]
    end
    it_should_behave_like "class"
  end

  describe "lambda function after doc-comment" do
    before do
      @doc = parse("/** */ MyClass = function() {}")["MyClass"]
    end
    it_should_behave_like "class"
  end

  describe "class name in both code and doc-comment" do
    before do
      @doc = parse("/** @class MyClass */ function YourClass() {}")["MyClass"]
    end
    it_should_behave_like "class"
  end

  describe "function beginning with underscore" do
    before do
      @doc = parse("/** */ function _Foo() {}")
    end
    it "does not imply class" do
      expect(@doc["_Foo"]).to eq(nil)
    end
  end

  describe "lowercase function name" do
    before do
      @doc = parse("/** */ function foo() {}")
    end
    it "does not imply class" do
      expect(@doc["foo"]).to eq(nil)
    end
  end

  describe "Ext.extend() in code" do
    before do
      @doc = parse("/** @class Your.Class */ /** */ MyClass = Ext.extend(Your.Class, {  });")["MyClass"]
    end
    it_should_behave_like "class"
    it "detects implied extends" do
      expect(@doc[:extends]).to eq("Your.Class")
    end
  end

  shared_examples_for "Ext.define" do
    it_should_behave_like "class"
    it "detects implied extends" do
      expect(@doc[:extends]).to eq("Your.Class")
    end
    it "detects implied mixins" do
      expect(Set.new(@doc[:mixins])).to eq(Set.new(["Ext.util.Observable", "Foo.Bar"]))
    end
    it "detects implied alternateClassNames" do
      expect(@doc[:alternateClassNames]).to eq(["JustClass"])
    end
    it "detects implied singleton" do
      expect(@doc[:singleton]).to eq(true)
    end
    it "detects required classes" do
      expect(@doc[:requires]).to eq(["ClassA", "ClassB"])
    end
    it "detects used classes" do
      expect(@doc[:uses]).to eq(["ClassC"])
    end
  end

  describe "basic Ext.define() in code" do
    before do
      @doc = parse(<<-EOS)["MyClass"]
        /** @class Your.Class */
        /** @class Ext.util.Observable */
        /** @class Foo.Bar */

        /** */
        Ext.define('MyClass', {
          extend: 'Your.Class',
          mixins: {
            obs: 'Ext.util.Observable',
            bar: 'Foo.Bar'
          },
          alternateClassName: 'JustClass',
          singleton: true,
          requires: ['ClassA', 'ClassB'],
          uses: 'ClassC'
        });
      EOS
    end
    it_should_behave_like "Ext.define"
  end

  describe "Ext.ClassManager.create() instead of Ext.define()" do
    before do
      @doc = parse(<<-EOS)["MyClass"]
        /** @class Ext.Base */

        /** */
        Ext.ClassManager.create('MyClass', {
        });
      EOS
    end
    it_should_behave_like "class"
  end

  describe "complex Ext.define() in code" do
    before do
      @doc = parse(<<-EOS)["MyClass"]
        /** @class Your.Class */
        /** @class Ext.util.Observable */
        /** @class Foo.Bar */

        /** */
        Ext.define('MyClass', {
          blah: true,
          extend: 'Your.Class',
          uses: ['ClassC'],
          conf: {foo: 10},
          singleton: true,
          alternateClassName: ['JustClass'],
          stuff: ["foo", "bar"],
          requires: ['ClassA', 'ClassB'],
          mixins: [
            'Ext.util.Observable',
            'Foo.Bar'
          ]
        });
      EOS
    end
    it_should_behave_like "Ext.define"
  end

  describe "explicit @tags overriding Ext.define()" do
    before do
      @doc = parse(<<-EOS)["MyClass"]
        /** @class Your.Class */
        /** @class Ext.util.Observable */
        /** @class Foo.Bar */

        /**
         * @class MyClass
         * @extends Your.Class
         * @uses ClassC
         * @requires ClassA
         * @requires ClassB
         * @alternateClassName JustClass
         * @mixins Ext.util.Observable
         * @mixins Foo.Bar
         * @singleton
         */
        Ext.define('MyClassXXX', {
          extend: 'Your.ClassXXX',
          uses: ['CCC'],
          singleton: false,
          alternateClassName: ['JustClassXXX'],
          requires: ['AAA'],
          mixins: ['BBB']
        });
      EOS
    end
    it_should_behave_like "Ext.define"
  end

  describe "Ext.define() without extend" do
    before do
      @doc = parse(<<-EOS)["MyClass"]
        /** @class Ext.Base */

        /** */
        Ext.define('MyClass', {
        });
      EOS
    end
    it "automatically extends from Ext.Base" do
      expect(@doc[:extends]).to eq("Ext.Base")
    end
  end

  describe "member docs after class doc" do
    before do
      @classes = parse(<<-EOS)
        /** @class Ext.Panel */

        /**
         * @class
         */
        var MyClass = Ext.extend(Ext.Panel, {
          /**
           * @cfg
           */
          fast: false,
          /**
           * @property
           */
          length: 0,
          /**
           */
          doStuff: function() {
            this.addEvents(
              /**
               * @event
               */
              'touch'
            );
          }
        });
      EOS
      @doc = @classes["MyClass"]
    end
    it "results in only one item" do
      expect(@classes.length).to eq(2) # account the pseudo Ext.Panel class
    end
    it_should_behave_like "class"

    it "should have 4 members" do
      expect(@doc[:members].length).to eq(4)
    end
    it "should have a config" do
      expect(@doc[:members][0][:tagname]).to eq(:cfg)
    end
    it "should have propertiesy" do
      expect(@doc[:members][1][:tagname]).to eq(:property)
    end
    it "should have method" do
      expect(@doc[:members][2][:tagname]).to eq(:method)
    end
    it "should have event" do
      expect(@doc[:members][3][:tagname]).to eq(:event)
    end
  end

  describe "multiple classes" do
    before do
      @classes = parse(<<-EOS)
        /**
         * @class
         */
        function Foo(){}
        /**
         * @class
         */
        function Bar(){}
      EOS
    end

    it "results in multiple classes" do
      expect(@classes.length).to eq(2)
    end

    it "both are class tags" do
      @classes["Foo"][:tagname] == :class
      @classes["Bar"][:tagname] == :class
    end

    it "names come in order" do
      @classes["Foo"][:name] == "Foo"
      @classes["Bar"][:name] == "Bar"
    end
  end

  describe "one class many times" do
    before do
      @classes = parse(<<-EOS)
        /** @class Bar */
        /** @class Mix1 */
        /** @class Mix2 */

        /**
         * @class Foo
         */
          /** @cfg c1 */
          /** @method fun1 */
          /** @event eve1 */
          /** @property prop1 */
        /**
         * @class Foo
         * @extends Bar
         * @mixins Mix1
         * @alternateClassNames AltClassic
         * Second description.
         * @private
         */
          /** @cfg c2 */
          /** @method fun2 */
          /** @event eve3 */
          /** @property prop2 */
        /**
         * @class Foo
         * @extends Bazaar
         * @mixins Mix2
         * @singleton
         * Third description.
         */
          /** @cfg c3 */
          /** @method fun3 */
          /** @event eve3 */
          /** @property prop3 */
      EOS
    end

    it "results in only one class" do
      expect(@classes.length).to eq(4) # account the three pseudo-classes
    end

    it "takes class doc from first doc-block that has one" do
      expect(@classes["Foo"][:doc]).to eq("Second description.")
    end

    it "takes @extends from first doc-block that has one" do
      expect(@classes["Foo"][:extends]).to eq("Bar")
    end

    it "is singleton when one doc-block is singleton" do
      expect(@classes["Foo"][:singleton]).to eq(true)
    end

    it "is private when one doc-block is private" do
      expect(@classes["Foo"][:private]).to eq(true)
    end

    it "combines all mixins" do
      expect(@classes["Foo"][:mixins].length).to eq(2)
    end

    it "combines all alternateClassNames" do
      expect(@classes["Foo"][:alternateClassNames].length).to eq(1)
    end

    it "combines all members" do
      expect(@classes["Foo"][:members].length).to eq(3 * 4)
    end
  end

  describe "class Foo following class with Foo as alternateClassName" do
    before do
      @classes = parse(<<-EOS)
        /**
         * @class Person
         * @alternateClassName Foo
         */
        /**
         * @class Foo
         */
      EOS
    end

    it "results in only one class" do
      expect(@classes.length).to eq(1)
    end
  end

  describe "class Foo preceding class with Foo as alternateClassName" do
    before do
      @classes = parse(<<-EOS)
        /**
         * @class Foo
         */
        /**
         * @class Person
         * @alternateClassName Foo
         */
      EOS
    end

    it "results in only one class" do
      expect(@classes.length).to eq(1)
    end
  end

  describe "Class with itself as alternateClassName" do
    before do
      @classes = parse(<<-EOS)
        /**
         * @class Foo
         * @alternateClassName Foo
         */
      EOS
    end

    it "results still in one class" do
      expect(@classes.length).to eq(1)
    end
  end


  describe "@extend followed by class name in {curly brackets}" do
    before do
      @doc = parse(<<-EOS)["Foo"]
        /** @class Bar.Baz */

        /**
         * @class Foo
         * @extends {Bar.Baz}
         */
      EOS
    end
    it "detectes the name of the extended class" do
      expect(@doc[:extends]).to eq("Bar.Baz")
    end
  end


  shared_examples_for "extending Object" do
    it "has extends == nil" do
      expect(@doc[:extends]).to eq(nil)
    end
  end

  describe "Class explicitly extending Object" do
    before do
      @doc = parse(<<-EOS)["Foo"]
        /**
         * @class Foo
         * @extends Object
         */
      EOS
    end
    it_should_behave_like "extending Object"
  end

  describe "Ext.define extending Object" do
    before do
      @doc = parse(<<-EOS)["Foo"]
        /** */
        Ext.define("Foo", {extend: "Object"});
      EOS
    end
    it_should_behave_like "extending Object"
  end

  describe "Ext.extend extending Object" do
    before do
      @doc = parse(<<-EOS)["Foo"]
        /** */
        Foo = Ext.extend(Object, { });
      EOS
    end
    it_should_behave_like "extending Object"
  end

  describe "Explicit class without @extends" do
    before do
      @doc = parse(<<-EOS)["Foo"]
        /** @class Foo */
      EOS
    end
    it_should_behave_like "extending Object"
  end

  describe "explicit class followed by normal function" do
    before do
      @doc = parse(<<-EOS)["foo"]
        /** @class */
        function foo(a, b, c) {
            return this;
        }
      EOS
    end

    it "detects class name" do
      expect(@doc[:name]).to eq("foo")
    end

    it "doesn't detect parameters" do
      expect(@doc[:params]).to eq(nil)
    end

    it "doesn't detect chainable" do
      expect(@doc[:chainable]).to eq(nil)
    end
  end
end
