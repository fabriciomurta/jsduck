require "jsduck/inline_examples"
require "jsduck/format/doc"

describe JsDuck::InlineExamples do

  def extract(doc, opts=nil)
    html = (opts == :html) ? doc : JsDuck::Format::Doc.new.format(doc)
    result = JsDuck::InlineExamples.new.extract(html)
    (opts == :raw) ? result : result.map {|ex| ex[:code] }
  end

  it "finds no examples from empty string" do
    expect(extract("")).to eq([])
  end

  it "finds no examples from simple text" do
    expect(extract("bla bla bla")).to eq([])
  end

  it "finds no examples from code blocks without @example tag" do
    expect(extract(<<-EOS)).to eq([])
Here's some code:

    My code

    EOS
  end

  it "finds one single-line example" do
    expect(extract(<<-EOS)).to eq(["My code\n"])
    @example
    My code
    EOS
  end

  it "finds one multi-line example" do
    expect(extract(<<-EOS)).to eq(["My code\n\nMore code\n"])
    @example
    My code

    More code
    EOS
  end

  it "finds two examples" do
    expect(extract(<<-EOS)).to eq(["My code 1\n", "My code 2\n"])
First example:

    @example
    My code 1

And another...

    @example
    My code 2
    EOS
  end

  # Escaping

  it "preserves HTML inside example" do
    expect(extract(<<-EOS)).to eq(["document.write('<b>Hello</b>');\n"])
    @example
    document.write('<b>Hello</b>');
    EOS
  end

  it "ignores links inside examples" do
    expect(extract(<<-EOS, :html)).to eq(["Ext.define();\n"])
<pre class='inline-example '><code><a href="#!/api/Ext">Ext</a>.define();
</code></pre>
EOS
  end

  # Options

  it "detects options after @example tag" do
    expect(extract(<<-EOS, :raw)).to eq([{:code => "foo();\n", :options => {"raw" => true, "blah" => true}}])
    @example raw blah
    foo();
    EOS
  end

  it "detects no options when none of them after @example tag" do
    expect(extract(<<-EOS, :raw)).to eq([{:code => "foo();\n", :options => {}}])
    @example
    foo();
    EOS
  end

end
