require "jsduck/merger"

describe JsDuck::Merger do

  def merge(docset, filename="", linenr=0)
    return JsDuck::Merger.new.merge(docset, filename, linenr)
  end

  describe "only name in code" do
    before do
      @doc = merge({
        :tagname => :cfg,
        :comment => {
          :tagname => :cfg,
          :name => nil,
          :type => "String",
          :doc => "My Config"
        },
        :code => {
          :tagname => :property,
          :name => "option",
        },
      }, "somefile.js", 15)
    end

    it "gets tagname from doc" do
      expect(@doc[:tagname]).to eq(:cfg)
    end
    it "gets type from doc" do
      expect(@doc[:type]).to eq("String")
    end
    it "gets documentation from doc" do
      expect(@doc[:doc]).to eq("My Config")
    end
    it "gets name from code" do
      expect(@doc[:name]).to eq("option")
    end
    it "keeps line number data" do
      expect(@doc[:files][0][:linenr]).to eq(15)
    end
  end

  describe "most stuff in code" do
    before do
      @doc = merge({
        :tagname => :property,
        :comment => {
          :tagname => :property,
          :name => nil,
          :type => nil,
          :doc => "Hello world"
        },
        :code => {
          :tagname => :property,
          :name => "some.prop",
          :type => "Boolean",
        }
      })
    end

    it "gets tagname from code" do
      expect(@doc[:tagname]).to eq(:property)
    end
    it "gets type from code" do
      expect(@doc[:type]).to eq("Boolean")
    end
    it "gets documentation from doc" do
      expect(@doc[:doc]).to eq("Hello world")
    end
    it "gets name from code" do
      expect(@doc[:name]).to eq("prop")
    end
  end

end
