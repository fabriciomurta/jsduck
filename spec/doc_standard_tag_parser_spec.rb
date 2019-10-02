require "jsduck/doc/scanner"
require "jsduck/doc/standard_tag_parser"

describe JsDuck::Doc::StandardTagParser do

  def parse(str, opts)
    scanner = JsDuck::Doc::Scanner.new
    scanner.input = StringScanner.new(str)
    std_parser = JsDuck::Doc::StandardTagParser.new(scanner)
    return std_parser.parse(opts)
  end

  it "Returns empty hash when no options specified" do
    expect(parse("Whatever...", {})).to eq({})
  end

  it "adds :tagname to returned data" do
    expect(parse("Whatever...", {:tagname => "blah"})).to eq({:tagname => "blah"})
  end

  it "parses :type" do
    expect(parse("{Foo}", {:type => true})).to eq({:type => "Foo"})
  end

  it "parses :type and :optional" do
    expect(parse("{Foo=}", {:type => true, :optional => true})).to eq(
      {:type => "Foo", :optional => true}
    )
  end

  it "ignores optionality in :type when no :optional specified" do
    expect(parse("{Foo=}", {:type => true})).to eq(
      {:type => "Foo"}
    )
  end

  it "parses :name" do
    expect(parse("some_ident", {:name => true})).to eq({:name => "some_ident"})
  end

  it "parses :name and :optional" do
    expect(parse("[ident]", {:name => true, :optional => true})).to eq(
      {:name => "ident", :optional => true}
    )
  end

  it "fails to parse :name when name in brackets but no :optional specified" do
    expect(parse("[ident]", {:name => true})).to eq({})
  end

  it "parses :name, :default and :optional" do
    expect(parse("[ident=10]", {:name => true, :default => true, :optional => true})).to eq(
      {:name => "ident", :default => "10", :optional => true}
    )
  end

  it "parses :name and :default without optionality" do
    expect(parse("ident=10", {:name => true, :default => true})).to eq(
      {:name => "ident", :default => "10"}
    )
  end

  it "parses quoted :default value" do
    expect(parse("ident = 'Hello, world!'", {:name => true, :default => true})).to eq(
      {:name => "ident", :default => "'Hello, world!'"}
    )
  end

  it "parses array :default value" do
    expect(parse("ident = [1, 2, 3, 4]", {:name => true, :default => true})).to eq(
      {:name => "ident", :default => "[1, 2, 3, 4]"}
    )
  end

  it "ignores stuff after :default value" do
    expect(parse("ident = 15.5 Blah", {:name => true, :default => true})).to eq(
      {:name => "ident", :default => "15.5"}
    )
  end

end
