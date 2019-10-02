require "jsduck/options/parser"
require "jsduck/util/null_object"

describe JsDuck::Options::Parser do
  before :all do
    file_class = JsDuck::Util::NullObject.new({
        :dirname => Proc.new {|x| x },
        :expand_path => Proc.new {|x, pwd| x },
        :exists? => false,
      })
    @parser = JsDuck::Options::Parser.new(file_class)
  end

  def parse(*argv)
    @parser.parse(argv)
  end

  describe :input_files do
    it "defaults to empty array" do
      expect(parse("-o", "foo/").input_files).to eq([])
    end

    it "treats empty input files list as invalid" do
      expect(parse("-o", "foo/").validate!(:input_files)).not_to eq(nil)
    end

    it "contains all non-option arguments" do
      expect(parse("foo.js", "bar.js").input_files).to eq(["foo.js", "bar.js"])
    end

    it "is populated by --builtin-classes" do
      parse("--builtin-classes").input_files[0].should =~ /js-classes$/
    end

    it "is valid when populated by --builtin-classes" do
      expect(parse("--builtin-classes").validate!(:input_files)).to eq(nil)
    end
  end

  describe :export do
    it "accepts --export=full" do
      opts = parse("--export", "full")
      expect(opts.validate!(:export)).to eq(nil)
      expect(opts.export).to eq(:full)
    end

    it "accepts --export=examples" do
      opts = parse("--export", "examples")
      expect(opts.validate!(:export)).to eq(nil)
      expect(opts.export).to eq(:examples)
    end

    it "doesn't accept --export=foo" do
      opts = parse("--export", "foo")
      expect(opts.validate!(:export)).not_to eq(nil)
    end

    it "is valid when no export option specified" do
      opts = parse()
      expect(opts.validate!(:export)).to eq(nil)
    end
  end

  describe :guides_toc_level do
    it "defaults to 2" do
      expect(parse().guides_toc_level).to eq(2)
    end

    it "gets converted to integer" do
      expect(parse("--guides-toc-level", "6").guides_toc_level).to eq(6)
    end

    it "is valid when between 1..6" do
      opts = parse("--guides-toc-level", "1")
      expect(opts.validate!(:guides_toc_level)).to eq(nil)
    end

    it "is invalid when not a number" do
      opts = parse("--guides-toc-level", "hello")
      expect(opts.validate!(:guides_toc_level)).not_to eq(nil)
    end

    it "is invalid when larger then 6" do
      opts = parse("--guides-toc-level", "7")
      expect(opts.validate!(:guides_toc_level)).not_to eq(nil)
    end
  end

  describe :processes do
    it "defaults to nil" do
      opts = parse()
      expect(opts.validate!(:processes)).to eq(nil)
      expect(opts.processes).to eq(nil)
    end

    it "can be set to 0" do
      opts = parse("--processes", "0")
      expect(opts.validate!(:processes)).to eq(nil)
      expect(opts.processes).to eq(0)
    end

    it "can be set to any positive number" do
      opts = parse("--processes", "4")
      expect(opts.validate!(:processes)).to eq(nil)
      expect(opts.processes).to eq(4)
    end

    it "can not be set to a negative number" do
      opts = parse("--processes", "-6")
      expect(opts.validate!(:processes)).not_to eq(nil)
    end
  end

  describe :import do
    it "defaults to empty array" do
      expect(parse().import).to eq([])
    end

    it "expands into version and path components" do
      expect(parse("--import", "1.0:/vers/1", "--import", "2.0:/vers/2").import).to eq([
        {:version => "1.0", :path => "/vers/1"},
        {:version => "2.0", :path => "/vers/2"},
      ])
    end

    it "expands pathless version number into just :version" do
      expect(parse("--import", "3.0").import).to eq([
        {:version => "3.0"},
      ])
    end
  end

  describe :ext_namespaces do
    it "defaults to nil" do
      expect(parse().ext_namespaces).to eq(nil)
    end

    it "can be used with comma-separated list" do
      expect(parse("--ext-namespaces", "Foo,Bar").ext_namespaces).to eq(["Foo", "Bar"])
    end

    it "can not be used multiple times" do
      expect(parse("--ext-namespaces", "Foo", "--ext-namespaces", "Bar").ext_namespaces).to eq(["Bar"])
    end
  end

  describe :ignore_html do
    it "defaults to empty hash" do
      expect(parse().ignore_html).to eq({})
    end

    it "can be used with comma-separated list" do
      html = parse("--ignore-html", "em,strong").ignore_html
      expect(html).to include("em")
      expect(html).to include("strong")
    end

    it "can be used multiple times" do
      html = parse("--ignore-html", "em", "--ignore-html", "strong").ignore_html
      expect(html).to include("em")
      expect(html).to include("strong")
    end
  end

  describe "--debug" do
    it "is equivalent of --template=template --template-links" do
      opts = parse("--debug")
      expect(opts.template).to eq("template")
      expect(opts.template_links).to eq(true)
    end

    it "has a shorthand -d" do
      opts = parse("-d")
      expect(opts.template).to eq("template")
      expect(opts.template_links).to eq(true)
    end
  end

  describe :warnings do
    it "default to empty array" do
      expect(parse().warnings).to eq([])
    end

    it "are parsed with Warnings::Parser" do
      ws = parse("--warnings", "+foo,-bar").warnings
      expect(ws.length).to eq(2)
      expect(ws[0][:type]).to eq(:foo)
      expect(ws[0][:enabled]).to eq(true)
      expect(ws[1][:type]).to eq(:bar)
      expect(ws[1][:enabled]).to eq(false)
    end
  end

  describe :verbose do
    it "defaults to false" do
      expect(parse().verbose).to eq(false)
    end

    it "set to true when --verbose used" do
      expect(parse("--verbose").verbose).to eq(true)
    end

    it "set to true when -v used" do
      expect(parse("-v").verbose).to eq(true)
    end
  end

  describe :external do
    it "contains JavaScript builtins by default" do
      exts = parse().external
      %w(Object String Number Boolean RegExp Function Array Arguments Date).each do |name|
        expect(exts).to include(name)
      end
    end

    it "contains JavaScript builtin error classes by default" do
      exts = parse().external
      expect(exts).to include("Error")
      %w(Eval Range Reference Syntax Type URI).each do |name|
        expect(exts).to include("#{name}Error")
      end
    end

    it "contains the special anything-goes Mixed type" do
      expect(parse().external).to include("Mixed")
    end

    it "can be used multiple times" do
      exts = parse("--external", "MyClass", "--external", "YourClass").external
      expect(exts).to include("MyClass")
      expect(exts).to include("YourClass")
    end

    it "can be used with comma-separated list" do
      exts = parse("--external", "MyClass,YourClass").external
      expect(exts).to include("MyClass")
      expect(exts).to include("YourClass")
    end
  end

  # Turns :attribute_name into "--option-name" or "--no-option-name"
  def opt(attr, negate=false)
    (negate ? "--no-" : "--") + attr.to_s.gsub(/_/, '-')
  end

  # Boolean options
  {
    :seo => false,
    :tests => false,
    :source => true, # TODO
    :ignore_global => false,
    :ext4_events => nil, # TODO
    :touch_examples_ui => false,
    :cache => false,
    :warnings_exit_nonzero => false,
    :color => nil, # TODO
    :pretty_json => nil,
    :template_links => false,
  }.each do |attr, default|
    describe attr do
      it "defaults to #{default.inspect}" do
        expect(parse().send(attr)).to eq(default)
      end

      it "set to true when --#{attr} used" do
        expect(parse(opt(attr)).send(attr)).to eq(true)
      end

      it "set to false when --no-#{attr} used" do
        expect(parse(opt(attr, true)).send(attr)).to eq(false)
      end
    end
  end

  # Simple setters
  {
    :encoding => nil,
    :title => "Documentation - JSDuck",
    :footer => "Generated on {DATE} by {JSDUCK} {VERSION}.",
    :welcome => nil,
    :guides => nil,
    :videos => nil,
    :examples => nil,
    :categories => nil,
    :new_since => nil,
    :comments_url => nil,
    :comments_domain => nil,
    :examples_base_url => nil,
    :link => '<a href="#!/api/%c%-%m" rel="%c%-%m" class="docClass">%a</a>',
    :img => '<p><img src="%u" alt="%a" width="%w" height="%h"></p>',
    :eg_iframe => nil,
    :cache_dir => nil,
    :extjs_path => "extjs/ext-all.js",
    :local_storage_db => "docs",
  }.each do |attr, default|
    describe attr do
      it "defaults to #{default.inspect}" do
        expect(parse().send(attr)).to eq(default)
      end
      it "is set to given string value" do
        expect(parse(opt(attr), "some string").send(attr)).to eq("some string")
      end
    end
  end

  # HTML and CSS options that get concatenated
  [
    :head_html,
    :body_html,
    :css,
    :message,
  ].each do |attr|
    describe attr do
      it "defaults to empty string" do
        expect(parse().send(attr)).to eq("")
      end

      it "can be used multiple times" do
        expect(parse(opt(attr), "Some ", opt(attr), "text").send(attr)).to eq("Some text")
      end
    end
  end

  # Multiple paths
  [
    :exclude,
    :images,
    :tags,
  ].each do |attr|
    describe attr do
      it "defaults to empty array" do
        expect(parse().send(attr)).to eq([])
      end

      it "can be used multiple times" do
        expect(parse(opt(attr), "foo", opt(attr), "bar").send(attr)).to eq(["foo", "bar"])
      end

      it "can be used with comma-separated list" do
        expect(parse(opt(attr), "foo,bar").send(attr)).to eq(["foo", "bar"])
      end
    end
  end

end
