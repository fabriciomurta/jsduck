require "mini_parser"

describe JsDuck::Aggregator do

  def parse(string)
    Helper::MiniParser.parse(string)
  end

  def parse_member(string)
    parse(string)["global"][:members][0]
  end

  shared_examples_for "object with properties" do
    it "has name" do
      expect(@obj[:name]).to eq(@name)
    end

    it "has type" do
      expect(@obj[:type]).to eq("Object")
    end

    it "has doc" do
      expect(@obj[:doc]).to eq("Geographical coordinates")
    end

    it "contains 2 properties" do
      expect(@obj[:properties].length).to eq(2)
    end

    describe "first property" do
      before do
        @prop = @obj[:properties][0]
      end

      it "has name without namespace" do
        expect(@prop[:name]).to eq("lat")
      end

      it "has type" do
        expect(@prop[:type]).to eq("Object")
      end

      it "has doc" do
        expect(@prop[:doc]).to eq("Latitude")
      end

      it "contains 2 subproperties" do
        expect(@prop[:properties].length).to eq(2)
      end

      describe "first subproperty" do
        it "has name without namespace" do
          expect(@prop[:properties][0][:name]).to eq("numerator")
        end
      end

      describe "second subproperty" do
        it "has name without namespace" do
          expect(@prop[:properties][1][:name]).to eq("denominator")
        end
      end
    end

    describe "second property" do
      before do
        @prop = @obj[:properties][1]
      end

      it "has name without namespace" do
        expect(@prop[:name]).to eq("lng")
      end

      it "has type" do
        expect(@prop[:type]).to eq("Number")
      end

      it "has doc" do
        expect(@prop[:doc]).to eq("Longitude")
      end
    end
  end

  describe "method parameter with properties" do
    before do
      @doc = parse_member(<<-EOS)
        /**
         * Some function
         * @param {Object} coord Geographical coordinates
         * @param {Object} coord.lat Latitude
         * @param {Number} coord.lat.numerator Numerator part of a fraction
         * @param {Number} coord.lat.denominator Denominator part of a fraction
         * @param {Number} coord.lng Longitude
         */
        function foo(x, y) {}
      EOS
    end

    it "is interpreted as single parameter" do
      expect(@doc[:params].length).to eq(1)
    end

    describe "single param" do
      before do
        @obj = @doc[:params][0]
        @name = "coord"
      end

      it_should_behave_like "object with properties"
    end
  end

  describe "event parameter with properties" do
    before do
      @doc = parse_member(<<-EOS)
        /**
         * @event
         * Some event
         * @param {Object} coord Geographical coordinates
         * @param {Object} coord.lat Latitude
         * @param {Number} coord.lat.numerator Numerator part of a fraction
         * @param {Number} coord.lat.denominator Denominator part of a fraction
         * @param {Number} coord.lng Longitude
         */
        "foo"
      EOS
    end

    it "is interpreted as single parameter" do
      expect(@doc[:params].length).to eq(1)
    end

    describe "single param" do
      before do
        @obj = @doc[:params][0]
        @name = "coord"
      end

      it_should_behave_like "object with properties"
    end
  end

  describe "cfg with properties" do
    before do
      @doc = parse(<<-EOS)
        /**
         * @cfg {Object} coord Geographical coordinates
         * @cfg {Object} coord.lat Latitude
         * @cfg {Number} coord.lat.numerator Numerator part of a fraction
         * @cfg {Number} coord.lat.denominator Denominator part of a fraction
         * @cfg {Number} coord.lng Longitude
         */
      EOS
    end

    it "is interpreted as single config" do
      expect(@doc["global"][:members].length).to eq(1)
    end

    describe "the config" do
      before do
        @obj = @doc["global"][:members][0]
        @name = "coord"
      end

      it_should_behave_like "object with properties"
    end
  end

  describe "property with properties" do
    before do
      @doc = parse(<<-EOS)
        /**
         * @property {Object} coord Geographical coordinates
         * @property {Object} coord.lat Latitude
         * @property {Number} coord.lat.numerator Numerator part of a fraction
         * @property {Number} coord.lat.denominator Denominator part of a fraction
         * @property {Number} coord.lng Longitude
         */
      EOS
    end

    it "is interpreted as single property" do
      expect(@doc["global"][:members].length).to eq(1)
    end

    describe "the property" do
      before do
        @obj = @doc["global"][:members][0]
        @name = "coord"
      end

      it_should_behave_like "object with properties"
    end
  end

  describe "method return value with properties" do
    before do
      @obj = parse_member(<<-EOS)[:return]
        /**
         * Some function
         * @return {Object} Geographical coordinates
         * @return {Object} return.lat Latitude
         * @return {Number} return.lat.numerator Numerator part of a fraction
         * @return {Number} return.lat.denominator Denominator part of a fraction
         * @return {Number} return.lng Longitude
         */
        function foo() {}
      EOS
      @name = "return"
    end

    it_should_behave_like "object with properties"
  end

  # Tests with buggy syntax

  describe "config option with properties in wrong order" do
    before do
      @obj = parse_member(<<-EOS)
        /**
         * @cfg {Object} coord Geographical coordinates
         * @cfg {Number} coord.lat.numerator Numerator part of a fraction
         * @cfg {Number} coord.lat.denominator Denominator part of a fraction
         * @cfg {Object} coord.lat Latitude
         * @cfg {Number} coord.lng Longitude
         */
      EOS
      @name = "coord"
    end

    it_should_behave_like "object with properties"
  end

  describe "only namespaced config options" do
    before do
      @doc = parse_member(<<-EOS)
        /**
         * @cfg {Number} coord.lat Latitude
         * @cfg {Number} coord.lng Latitude
         */
      EOS
    end

    it "interpreted as just one config" do
      expect(@doc[:name]).to eq("coord")
    end
  end

  describe "normal config option name with dot after it" do
    before do
      @doc = parse_member(<<-EOS)
        /**
         * @cfg {Number} coord. Coordinate
         */
      EOS
    end

    it "has no dot in name" do
      expect(@doc[:name]).to eq("coord")
    end

    it "has dot in doc" do
      expect(@doc[:doc]).to eq(". Coordinate")
    end
  end

  describe "normal config option name with dot before it" do
    before do
      @doc = parse_member(<<-EOS)
        /**
         * @cfg {Number} .coord Coordinate
         */
      EOS
    end

    it "has empty name" do
      expect(@doc[:name]).to eq("")
    end

    it "has dot in doc" do
      expect(@doc[:doc]).to eq(".coord Coordinate")
    end
  end

end
