require "mini_parser"

describe JsDuck::Aggregator do
  def parse(string)
    Helper::MiniParser.parse(string, {:accessors => true})
  end

  def parse_to_members_hash(string)
    docs = parse(string)

    members = {}
    docs["MyClass"][:members].each do |m|
      members[m[:name]] = m
    end

    return members
  end

  describe "@cfg foo with @accessor" do
    before do
      @members = parse_to_members_hash(<<-EOF)
        /** @class MyClass */
          /**
           * @cfg {String} foo
           * Original comment.
           * @accessor
           */
      EOF
    end

    it "creates getFoo method" do
      expect(@members).to have_key("getFoo")
    end

    it "sets getFoo return type to @cfg type" do
      expect(@members["getFoo"][:return][:type]).to eq("String")
    end

    it "sets getFoo to have 0 parameters" do
      expect(@members["getFoo"][:params].length).to eq(0)
    end

    it "sets getFoo owner @cfg owner" do
      expect(@members["getFoo"][:owner]).to eq("MyClass")
    end

    it "generates dummy docs for getFoo" do
      expect(@members["getFoo"][:doc]).to eq("Returns the value of {@link #cfg-foo}.")
    end

    it "creates setFoo method" do
      expect(@members).to have_key("setFoo")
    end

    it "sets setFoo return type to nil" do
      expect(@members["setFoo"][:return]).to eq(nil)
    end

    it "sets setFoo parameter type to @cfg type" do
      expect(@members["setFoo"][:params][0][:type]).to eq("String")
    end

    it "sets setFoo parameter name to @cfg name" do
      expect(@members["setFoo"][:params][0][:name]).to eq("foo")
    end

    it "generates dummy docs for setFoo parameter" do
      expect(@members["setFoo"][:params][0][:doc]).to eq("The new value.")
    end

    it "sets setFoo owner @cfg owner" do
      expect(@members["setFoo"][:owner]).to eq("MyClass")
    end

    it "generates dummy docs for setFoo" do
      expect(@members["setFoo"][:doc]).to eq("Sets the value of {@link #cfg-foo}.")
    end

  end

  describe "@accessor config" do
    before do
      @members = parse_to_members_hash(<<-EOF)
        /** @class MyClass */
          /**
           * @cfg {String} foo
           * Original comment.
           * @accessor
           */
          /**
           * @cfg {String} bar
           * Original comment.
           * @accessor
           */
          /**
           * @method getFoo
           * Custom comment.
           */
          /**
           * @method setBar
           * Custom comment.
           */
      EOF
    end

    it "doesn't create getter when method already present" do
      expect(@members["getFoo"][:doc]).to eq("Custom comment.")
    end

    it "doesn't create setter when method already present" do
      expect(@members["setBar"][:doc]).to eq("Custom comment.")
    end

    it "creates getter when method not present" do
      expect(@members).to have_key("getBar")
    end

    it "creates setter when method not present" do
      expect(@members).to have_key("setFoo")
    end

  end

  describe "@accessor with other tags" do
    before do
      @members = parse_to_members_hash(<<-EOF)
        /** @class MyClass */
          /**
           * @cfg {String} foo
           * Original comment.
           * @accessor
           * @evented
           * @protected
           * @deprecated 2.0 Don't use it any more
           */
      EOF
    end

    it "adds @protected to getter" do
      expect(@members["getFoo"][:protected]).to eq(true)
    end

    it "adds @deprecated to getter" do
      expect(@members["getFoo"][:deprecated]).not_to eq(nil)
    end

    it "doesn't add @accessor to getter" do
      expect(@members["getFoo"][:accessor]).to eq(nil)
    end

    it "doesn't add @evented to getter" do
      expect(@members["getFoo"][:evented]).to eq(nil)
    end

    # Lighter tests for setter and event.
    # The same method takes care of inheriting in all cases.

    it "adds @protected to setter" do
      expect(@members["setFoo"][:protected]).to eq(true)
    end

    it "adds @protected to event" do
      expect(@members["foochange"][:protected]).to eq(true)
    end
  end

  describe "@accessor tag on private cfg" do
    before do
      @docs = parse(<<-EOF)
        /** @class MyClass */
          /**
           * @cfg {String} foo
           * @private
           * @accessor
           * @evented
           */
      EOF
      @accessors = @docs["MyClass"][:members].find_all {|m| m[:tagname] == :method }
      @events = @docs["MyClass"][:members].find_all {|m| m[:tagname] == :event }
    end

    it "creates accessors" do
      expect(@accessors.length).to eq(2)
    end

    it "creates private getter" do
      expect(@accessors[0][:private]).to eq(true)
    end

    it "creates private setter" do
      expect(@accessors[1][:private]).to eq(true)
    end

    it "creates private event" do
      expect(@events[0][:private]).to eq(true)
    end
  end

  describe "@accessor tag on hidden cfg" do
    before do
      @docs = parse(<<-EOF)
        /** @class MyClass */
          /**
           * @cfg {String} foo
           * @hide
           * @accessor
           */
      EOF
      @accessors = @docs["MyClass"][:members].find_all {|m| m[:tagname] == :method }
    end

    it "creates accessors" do
      expect(@accessors.length).to eq(2)
    end

    it "creates hidden getter" do
      expect(@accessors[0][:hide]).to eq(true)
    end

    it "creates hidden setter" do
      expect(@accessors[1][:hide]).to eq(true)
    end
  end

  describe "@cfg foo with @evented @accessor" do
    before do
      @members = parse_to_members_hash(<<-EOF)
        /** @class MyClass */
          /**
           * @cfg {String} foo
           * Original comment.
           * @accessor
           * @evented
           */
      EOF
    end

    it "creates foochange event" do
      expect(@members["foochange"][:name]).to eq("foochange")
    end

    it "creates documentation for foochange event" do
      expect(@members["foochange"][:doc]).to eq(
        "Fires when the {@link #cfg-foo} configuration is changed by {@link #method-setFoo}."
      )
    end

    it "has 3 params" do
      expect(@members["foochange"][:params].length).to eq(3)
    end

    describe "1st param" do
      before do
        @param = @members["foochange"][:params][0]
      end

      it "is this" do
        expect(@param[:name]).to eq("this")
      end

      it "is the same type as the class" do
        expect(@param[:type]).to eq("MyClass")
      end

      it "has documentation" do
        expect(@param[:doc]).to eq("The MyClass instance.")
      end
    end

    describe "2nd param" do
      before do
        @param = @members["foochange"][:params][1]
      end

      it "is value" do
        expect(@param[:name]).to eq("value")
      end

      it "is the same type as the cfg" do
        expect(@param[:type]).to eq("String")
      end

      it "has documentation" do
        expect(@param[:doc]).to eq("The new value being set.")
      end
    end

    describe "3rd param" do
      before do
        @param = @members["foochange"][:params][2]
      end

      it "is oldValue" do
        expect(@param[:name]).to eq("oldValue")
      end

      it "is the same type as the cfg" do
        expect(@param[:type]).to eq("String")
      end

      it "has documentation" do
        expect(@param[:doc]).to eq("The existing value.")
      end
    end

  end

  describe "@evented @accessor with existing event" do
    before do
      @docs = parse(<<-EOF)
        /** @class MyClass */
          /**
           * @cfg {String} fooBar
           * @accessor
           * @evented
           */
          /**
           * @event foobarchange
           * Event comment.
           */
      EOF
      @events = @docs["MyClass"][:members].find_all {|m| m[:tagname] == :event }
    end

    it "doesn't create any additional events" do
      expect(@events.length).to eq(1)
    end

    it "leaves the existing event as is." do
      expect(@events[0][:doc]).to eq("Event comment.")
    end
  end

end
