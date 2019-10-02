require "mini_parser"

describe JsDuck::Aggregator do
  def parse(string)
    Helper::MiniParser.parse(string, {
        :overrides => true,
        :inherit_doc => true,
        :filename => "blah.js"
      })
  end

  shared_examples_for "override" do
    it "gets :override property" do
      expect(@method).to have_key(:overrides)
    end

    it "lists parent method in :override property" do
      expect(@method[:overrides][0][:owner]).to eq("Parent")
    end

    it "lists name of the method in :override property" do
      expect(@method[:overrides][0][:name]).to eq("foo")
    end
  end

  describe "method overriding parent class method" do
    before do
      @docs = parse(<<-EOF)
        /** @class Parent */
          /** @method foo */

        /** @class Child @extends Parent */
          /** @method foo */
      EOF
      @method = @docs["Child"].find_members(:tagname => :method)[0]
    end

    it_should_behave_like "override"
  end

  describe "mixin method overriding parent class method" do
    before do
      @docs = parse(<<-EOF)
        /** @class Parent */
          /** @method foo */
        /** @class Mixin */
          /** @method foo */

        /** @class Child @extends Parent @mixins Mixin */
      EOF
      @method = @docs["Child"].find_members(:tagname => :method)[0]
    end

    it_should_behave_like "override"
  end

  describe "mixin method overriding multiple parent class methods" do
    before do
      @docs = parse(<<-EOF)
        /** @class Parent1 */
          /** @method foo */
        /** @class Parent2 */
          /** @method foo */
        /** @class Mixin */
          /** @method foo */

        /** @class Child1 @extends Parent1 @mixins Mixin */
        /** @class Child2 @extends Parent2 @mixins Mixin */
      EOF
      # Call #members on two child classes, this will init the
      # :overrides in Mixin class
      @docs["Child1"].find_members(:tagname => :method)[0]
      @docs["Child2"].find_members(:tagname => :method)[0]

      @method = @docs["Mixin"].find_members(:tagname => :method)[0]
    end

    it "gets :override property listing multiple methods" do
      expect(@method[:overrides].length).to eq(2)
    end
  end

  # Test for bug #465
  describe "overriding with multiple auto-detected members" do
    before do
      @docs = parse(<<-EOF)
        /** @class Ext.Base */

          /** */
          Ext.define('Base', {
              /** */
              foo: 1
          });

          /** */
          Ext.define('Child', {
              extend: 'Base',

              foo: 2
          });

          /** */
          Ext.define('GrandChild', {
              extend: 'Child',

              foo: 3
          });

          /** */
          Ext.define('GrandGrandChild', {
              extend: 'GrandChild',

              foo: 4
          });
      EOF
    end

    def get_overrides(cls)
      @docs[cls].find_members(:name => "foo")[0][:overrides]
    end


    it "lists just one override in Child class" do
      expect(get_overrides("Child").length).to eq(1)
    end

    it "lists just one override in GrandChild class" do
      expect(get_overrides("GrandChild").length).to eq(1)
    end

    it "lists just one override in GrandGrandChild class" do
      expect(get_overrides("GrandGrandChild").length).to eq(1)
    end


    it "lists Base as overridden in Child class" do
      expect(get_overrides("Child")[0][:owner]).to eq("Base")
    end

    it "lists Child as overridden in GrandChild class" do
      expect(get_overrides("GrandChild")[0][:owner]).to eq("Child")
    end

    it "lists GrandChild as overridden in GrandGrandChild class" do
      expect(get_overrides("GrandGrandChild")[0][:owner]).to eq("GrandChild")
    end

  end


end
