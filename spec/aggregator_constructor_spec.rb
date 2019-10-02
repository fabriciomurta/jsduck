require "mini_parser"

describe JsDuck::Aggregator do
  def parse(string)
    Helper::MiniParser.parse(string, {:inherit_doc => true})
  end

  shared_examples_for "constructor" do
    it "has one method" do
      expect(methods.length).to eq(1)
    end

    it "has method with name 'constructor'" do
      expect(methods[0][:name]).to eq("constructor")
    end

    it "has method with constructor docs" do
      expect(methods[0][:doc]).to eq("This constructs the class")
    end

    it "has method with needed parameters" do
      expect(methods[0][:params].length).to eq(1)
    end
  end

  describe "class with @constructor" do
    let(:methods) do
      parse(<<-EOS)["MyClass"][:members]
        /**
         * @class MyClass
         * Comment here.
         * @constructor
         * This constructs the class
         * @param {Number} nr
         */
      EOS
    end

    it_should_behave_like "constructor"
  end

  describe "class with method named constructor" do
    let(:methods) do
      parse(<<-EOS)["MyClass"][:members]
        /**
         * Comment here.
         */
        MyClass = {
            /**
             * @method constructor
             * This constructs the class
             * @param {Number} nr
             */
        };
      EOS
    end

    it_should_behave_like "constructor"
  end

  describe "class with member containing @constructor" do
    let(:methods) do
      parse(<<-EOS)["MyClass"][:members]
        /**
         * Comment here.
         */
        MyClass = {
            /**
             * @constructor
             * This constructs the class
             * @param {Number} nr
             */
        };
      EOS
    end

    it_should_behave_like "constructor"
  end

  describe "class with both @constructor tag and constructor property inside Ext.define()" do
    let(:methods) do
      parse(<<-EOS)["MyClass"][:members]
        /** @class Ext.Base */

        /**
         * Comment here.
         * @constructor
         * This constructs the class
         * @param {Number} nr
         */
        Ext.define("MyClass", {
            constructor: function() {
            }
        });
      EOS
    end

    it "detects just one constructor" do
      expect(methods.length).to eq(1)
    end
  end

  describe "class with constructor property inside Ext.define()" do
    let(:methods) do
      parse(<<-EOS)["MyClass"][:members]
        /** @class Ext.Base */

        /**
         * Comment here.
         * @private
         */
        Ext.define("MyClass", {
            constructor: function() {
            },
            foo: []
        });
      EOS
    end

    it "detects the constructor method" do
      expect(methods[0][:name]).to eq("constructor")
    end

    it "doesn't detect the constructor as private" do
      expect(methods[0][:private]).not_to eq(true)
    end
  end

end
