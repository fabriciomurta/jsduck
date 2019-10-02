require "jsduck/categories/file"

describe JsDuck::Categories::File do

  describe "#expand" do
    before do
      classes = [
        {:name => "Foo.Ahem"},
        {:name => "Foo.Ahum"},
        {:name => "Foo.Blah"},
        {:name => "Bar.Ahhh"},
      ]
      @categories = JsDuck::Categories::File.new("", classes)
    end

    it "expands class without * in name into the same class" do
      expect(@categories.expand("Foo.Ahem")).to eq(["Foo.Ahem"])
    end

    it "expands Foo.* into all classes in Foo namespace" do
      expect(@categories.expand("Foo.*")).to eq(["Foo.Ahem", "Foo.Ahum", "Foo.Blah"])
    end

    it "expands Foo.A* into all classes in Foo namespace beginning with A" do
      expect(@categories.expand("Foo.A*")).to eq(["Foo.Ahem", "Foo.Ahum"])
    end

    it "expands to empty array if no classes match the pattern" do
      expect(@categories.expand("Bazz*")).to eq([])
    end
  end

end
