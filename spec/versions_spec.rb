require "jsduck/process/versions"
require "jsduck/util/null_object"
require "jsduck/class"
require "ostruct"

describe JsDuck::Process::Versions do

  def current_version
    JsDuck::Util::NullObject.new(
      :[] => JsDuck::Util::NullObject.new( # class
        :[] => JsDuck::Util::NullObject.new( # member
          :length => 1.0 / 0))) # params count == Infinity
  end

  describe "without :new_since option" do
    before do
      @versions = [
        {
          :version => "1.0", :classes => {
            "VeryOldClass" => {"cfg-foo" => true},
            "ExplicitNewClass" => {},
          },
        },
        {
          :version => "2.0", :classes => {
            "VeryOldClass" => {"cfg-foo" => true, "cfg-bar" => true},
            "OldClass" => {},
            "ClassWithOldName" => {},
          },
        },
        {
          :version => "3.0", :classes => current_version
        }
      ]

      importer = JsDuck::Util::NullObject.new(:import => @versions)

      @relations = [
        {:name => "VeryOldClass", :alternateClassNames => [], :members => [
            {:tagname => :cfg, :id => "cfg-foo"},
            {:tagname => :cfg, :id => "cfg-bar"},
            {:tagname => :cfg, :id => "cfg-baz"},
            {:tagname => :cfg, :id => "cfg-zap", :since => "1.0"},
            {:tagname => :cfg, :id => "cfg-new", :new => true},
          ]},
        {:name => "OldClass", :alternateClassNames => []},
        {:name => "NewClass", :alternateClassNames => []},
        {:name => "ClassWithNewName", :alternateClassNames => ["ClassWithOldName"]},
        {:name => "ExplicitSinceClass", :since => "1.0", :alternateClassNames => []},
        {:name => "ExplicitNewClass", :new => true, :alternateClassNames => []},
      ].map {|cfg| JsDuck::Class.new(cfg) }

      opts = OpenStruct.new(:import => @versions)
      JsDuck::Process::Versions.new(@relations, opts, importer).process_all!

      # build className/member index for easy lookup in specs
      @stuff = {}
      @relations.each do |cls|
        @stuff[cls[:name]] = cls
        cls[:members].each do |cfg|
          @stuff[cls[:name]+"#"+cfg[:id]] = cfg
        end
      end
    end

    # @since

    it "adds @since 1.0 to VeryOldClass" do
      expect(@stuff["VeryOldClass"][:since]).to eq("1.0")
    end

    it "adds @since 2.0 to OldClass" do
      expect(@stuff["OldClass"][:since]).to eq("2.0")
    end

    it "adds @since 3.0 to NewClass" do
      expect(@stuff["NewClass"][:since]).to eq("3.0")
    end

    it "adds @since 2.0 to ClassWithNewName" do
      expect(@stuff["ClassWithNewName"][:since]).to eq("2.0")
    end

    it "doesn't override explicit @since 1.0 in ExplicitSinceClass" do
      expect(@stuff["ExplicitSinceClass"][:since]).to eq("1.0")
    end

    it "adds @since 1.0 to #foo" do
      expect(@stuff["VeryOldClass#cfg-foo"][:since]).to eq("1.0")
    end

    it "adds @since 2.0 to #bar" do
      expect(@stuff["VeryOldClass#cfg-bar"][:since]).to eq("2.0")
    end

    it "adds @since 3.0 to #baz" do
      expect(@stuff["VeryOldClass#cfg-baz"][:since]).to eq("3.0")
    end

    it "doesn't override explicit @since 1.0 in #zap" do
      expect(@stuff["VeryOldClass#cfg-zap"][:since]).to eq("1.0")
    end

    # @new

    it "doesn't add @new to VeryOldClass" do
      expect(@stuff["VeryOldClass"][:new]).not_to eq(true)
    end

    it "doesn't add @new to OldClass" do
      expect(@stuff["OldClass"][:new]).not_to eq(true)
    end

    it "adds @new to NewClass" do
      expect(@stuff["NewClass"][:new]).to eq(true)
    end

    it "doesn't add @new to ClassWithNewName" do
      expect(@stuff["ClassWithNewName"][:new]).not_to eq(true)
    end

    it "doesn't add @new to ExplicitSinceClass" do
      expect(@stuff["ExplicitSinceClass"][:new]).not_to eq(true)
    end

    it "keeps explicit @new on ExplicitNewClass" do
      # Though it seems like a weird case, there could be a situation
      # where 1.0 had class Foo, which was removed in 2.0, but in 3.0 a
      # completely unrelated Foo class was introduced.
      expect(@stuff["ExplicitNewClass"][:new]).to eq(true)
    end

    it "doesn't add @new to #foo" do
      expect(@stuff["VeryOldClass#cfg-foo"][:new]).not_to eq(true)
    end

    it "doesn't add @new to #bar" do
      expect(@stuff["VeryOldClass#cfg-bar"][:new]).not_to eq(true)
    end

    it "adds @new to #baz" do
      expect(@stuff["VeryOldClass#cfg-baz"][:new]).to eq(true)
    end

    it "doesn't add @new to #zap" do
      expect(@stuff["VeryOldClass#cfg-zap"][:new]).not_to eq(true)
    end

    it "keeps explicit @new in #new" do
      expect(@stuff["VeryOldClass#cfg-new"][:new]).to eq(true)
    end

  end

  describe "with explicit :new_since option" do
    before do
      @versions = [
        {
          :version => "1.0", :classes => {
            "VeryOldClass" => {},
          },
        },
        {
          :version => "2.0", :classes => {
            "OldClass" => {},
          },
        },
        {
          :version => "3.0", :classes => current_version
        }
      ]
      importer = JsDuck::Util::NullObject.new(:import => @versions)

      @relations = [
        {:name => "VeryOldClass", :alternateClassNames => []},
        {:name => "OldClass", :alternateClassNames => []},
        {:name => "NewClass", :alternateClassNames => []},
      ].map {|cfg| JsDuck::Class.new(cfg) }

      opts = OpenStruct.new(:import => @versions, :new_since => "2.0")
      JsDuck::Process::Versions.new(@relations, opts, importer).process_all!
    end

    # @since

    it "gives no @new to VeryOldClass" do
      expect(@relations[0][:new]).not_to eq(true)
    end

    it "gives @new to OldClass" do
      expect(@relations[1][:new]).to eq(true)
    end

    it "gives no @new to NewClass" do
      expect(@relations[2][:new]).to eq(true)
    end
  end

  describe "method parameters" do
    let(:relations) do
      versions = [
        {
          :version => "1.0", :classes => {
            "MyClass" => {"method-foo" => ["x"]},
          },
        },
        {
          :version => "2.0", :classes => {
            "MyClass" => {"method-foo" => ["x", "oldY"]},
          },
        },
        {
          :version => "3.0", :classes => current_version
        }
      ]
      importer = JsDuck::Util::NullObject.new(:import => versions)

      relations = [
        {:name => "MyClass", :alternateClassNames => [], :members => [
            {:tagname => :method, :id => "method-foo", :params => [
                {:name => "x"},
                {:name => "y"},
                {:name => "z"},
              ]},
            {:tagname => :method, :id => "method-bar", :since => "0.1", :params => [
                {:name => "x"},
              ]},
          ]},
      ].map {|cfg| JsDuck::Class.new(cfg) }

      opts = OpenStruct.new(:import => versions, :new_since => "3.0")
      JsDuck::Process::Versions.new(relations, opts, importer).process_all!

      relations
    end

    describe "method #foo" do
      let(:method) do
        relations[0][:members][0]
      end

      it "adds @since 1.0 to our method" do
        expect(method[:since]).to eq("1.0")
      end

      it "adds no @since to 1st param, because it's also from 1.0" do
        expect(method[:params][0][:since]).to eq(nil)
      end

      it "adds @since 2.0 to 2nd param (although it was named differently in 2.0)" do
        expect(method[:params][1][:since]).to eq("2.0")
      end

      it "adds @since 3.0 to 3rd param" do
        expect(method[:params][2][:since]).to eq("3.0")
      end

      it "adds @new to 3rd param" do
        expect(method[:params][2][:new]).to eq(true)
      end
    end

    describe "method with explicit @since 0.1" do
      let(:method) do
        relations[0][:members][1]
      end

      it "adds @since 0.1 to our method" do
        expect(method[:since]).to eq("0.1")
      end

      it "doesn't add a @since to parameter" do
        expect(method[:params][0][:since]).to eq(nil)
      end
    end

  end

end
