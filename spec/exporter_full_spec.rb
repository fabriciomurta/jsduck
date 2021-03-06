require "jsduck/exporter/full"
require "jsduck/class"
require "jsduck/relations"
require "class_factory"

describe JsDuck::Exporter::Full do

  describe "#export" do

    let(:cls) do
      Helper::ClassFactory.create({
        :name => "Foo",
        :members => [
          {:tagname => :cfg, :name => "foo"},
          {:tagname => :cfg, :name => "bar"},
          {:tagname => :cfg, :name => "zap"},
          {:tagname => :cfg, :name => "baz"},
          {:tagname => :method, :name => "addFoo"},
          {:tagname => :method, :name => "addBaz"},
          {:tagname => :method, :name => "constructor"},
          {:tagname => :method, :name => "statGet", :static => true},
          {:tagname => :event, :name => "beforebar"},
        ],
      })
    end

    let(:result) do
      JsDuck::Exporter::Full.new(JsDuck::Relations.new([cls])).export(cls)
    end

    it "places all members inside :members field" do
      expect(result[:members].length).to eq(9)
    end

    it "sorts configs alphabetically" do
      configs = result[:members].find_all {|m| m[:tagname] == :cfg }
      expect(configs.map {|m| m[:name] }).to eq(["bar", "baz", "foo", "zap"])
    end

    it "sorts constructor first when sorting methods and static methods last" do
      methods = result[:members].find_all {|m| m[:tagname] == :method }
      expect(methods.map {|m| m[:name] }).to eq(["constructor", "addBaz", "addFoo", "statGet"])
    end

  end

end
