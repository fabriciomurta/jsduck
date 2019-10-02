require "mini_parser"

describe JsDuck::Aggregator do

  def parse(string)
    Helper::MiniParser.parse(string)
  end

  def parse_member(string)
    parse(string)["global"][:members][0]
  end

  shared_examples_for "example cfg" do
    it "creates cfg" do
      expect(@doc[:tagname]).to eq(:cfg)
    end

    it "detects name" do
      expect(@doc[:name]).to eq("foo")
    end

    it "detects type" do
      expect(@doc[:type]).to eq("String")
    end

    it "takes documentation from doc-comment" do
      expect(@doc[:doc]).to eq("Some documentation.")
    end
  end

  describe "explicit @cfg" do
    before do
      @doc = parse_member(<<-EOS)
        /**
         * @cfg {String} foo
         * Some documentation.
         */
      EOS
    end
    it_should_behave_like "example cfg"
  end

  describe "implicit @cfg" do
    before do
      @doc = parse_member(<<-EOS)
      ({/**
         * @cfg
         * Some documentation.
         */
        foo: "asdf" })
      EOS
    end
    it_should_behave_like "example cfg"
  end

  describe "typeless @cfg" do
    before do
      @doc = parse_member(<<-EOS)
      ({/**
         * @cfg
         * Some documentation.
         */
        foo: func() })
      EOS
    end

    it "default type is Object" do
      expect(@doc[:type]).to eq("Object")
    end
  end

  describe "null @cfg" do
    before do
      @doc = parse_member(<<-EOS)
      ({/**
         * @cfg
         * Some documentation.
         */
        foo: null })
      EOS
    end

    it "default type is Object" do
      expect(@doc[:type]).to eq("Object")
    end
  end

  describe "@cfg with dash in name" do
    before do
      @doc = parse_member(<<-EOS)
        /**
         * @cfg {String} foo-bar
         * Some documentation.
         */
      EOS
    end

    it "detects the name" do
      expect(@doc[:name]).to eq("foo-bar")
    end
  end

  describe "@cfg with uppercase name" do
    before do
      @doc = parse_member(<<-EOS)
      ({/**
         * @cfg {String} Foo
         */
        Foo: 12 })
      EOS
    end

    it "is detected as config" do
      expect(@doc[:tagname]).to eq(:cfg)
    end
  end

  describe "@cfg with uppercase name after description" do
    before do
      @doc = parse_member(<<-EOS)
      ({/**
         * Docs here
         * @cfg {String} Foo
         */
        Foo: 12 })
      EOS
    end

    it "is detected as config" do
      expect(@doc[:tagname]).to eq(:cfg)
    end
  end

  def parse_config_code(propertyName)
    parse(<<-EOS)["MyClass"][:members]
      /** @class Ext.Base */

      /**
       * Some documentation.
       */
      Ext.define("MyClass", {
          #{propertyName}: {
              foo: 42,
              /** Docs for bar */
              bar: "hello"
          }
      });
    EOS
  end

  shared_examples_for "config" do
    # Generic tests

    it "finds configs" do
      expect(cfg.all? {|m| m[:tagname] == :cfg }).to eq(true)
    end

    it "finds two configs" do
      expect(cfg.length).to eq(2)
    end

    describe "auto-detected config" do
      it "with :inheritdoc flag" do
        expect(cfg[0][:inheritdoc]).to eq({})
      end

      it "with :accessor flag" do
        expect(cfg[0][:accessor]).to eq(true)
      end

      it "with :autodetected flag" do
        expect(cfg[0][:autodetected][:tagname]).to eq(:cfg)
      end

      it "with :linenr field" do
        expect(cfg[0][:linenr]).to eq(8)
      end
    end

    describe "documented config" do
      it "with docs" do
        expect(cfg[1][:doc]).to eq("Docs for bar")
      end

      it "with owner" do
        expect(cfg[1][:owner]).to eq("MyClass")
      end

      it "as public" do
        cfg[1][:private].should_not == true
      end

      it "with :accessor flag" do
        expect(cfg[1][:accessor]).to eq(true)
      end
    end
  end

  describe "detecting Ext.define() with config:" do
    let(:cfg) { parse_config_code("config") }

    it_should_behave_like "config"
  end

  describe "detecting Ext.define() with cachedConfig:" do
    let(:cfg) { parse_config_code("cachedConfig") }

    it_should_behave_like "config"
  end

  describe "detecting Ext.define() with eventedConfig:" do
    let(:cfg) { parse_config_code("eventedConfig") }

    it_should_behave_like "config"

    it "auto-detected config with :evented flag" do
      expect(cfg[0][:evented]).to eq(true)
    end

    it "documented config with :evented flag" do
      expect(cfg[1][:evented]).to eq(true)
    end
  end

  describe "detecting Ext.define() with all kind of configs" do
    let(:cfg) do
      parse(<<-EOS)["MyClass"][:members]
        /** @class Ext.Base */

        /**
         * Some documentation.
         */
        Ext.define("MyClass", {
            config: {
                blah: 7
            },
            cachedConfig: {
                foo: 42,
                bar: "hello"
            },
            eventedConfig: {
                baz: /fafa/
            }
        });
      EOS
    end

    it "merges all configs together" do
      expect(cfg.length).to eq(4)
    end
  end

  describe "Ext.define() with line-comment before config:" do
    let(:cfg) do
      parse(<<-EOS)["MyClass"][:members]
        /** @class Ext.Base */

        /**
         * Some documentation.
         */
        Ext.define("MyClass", {
            config: {
                // My config
                blah: 7
            }
        });
      EOS
    end

    it "detects one config" do
      expect(cfg.length).to eq(1)
    end

    it "detects documentation" do
      expect(cfg[0][:doc]).to eq("My config")
    end

    it "detects the config with :inheritdoc flag" do
      expect(cfg[0][:inheritdoc]).to eq({})
    end

    it "detects the config with :autodetected flag" do
      expect(cfg[0][:autodetected][:tagname]).to eq(:cfg)
    end
  end

end
