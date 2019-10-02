require 'jsduck/css/parser'

# We test the Css::Type through Css::Parser to avoid the whole
# setup of Sass::Engine.
describe JsDuck::Css::Type do

  def detect(expr)
    ast = JsDuck::Css::Parser.new("/** */ $foo: #{expr};").parse
    ast[0][:code][:type]
  end

  describe "detects" do
    it "plain number --> number" do
      expect(detect("3.14")).to eq("number")
    end
    it "percentage --> number" do
      expect(detect("10%")).to eq("number")
    end
    it "measurement --> number" do
      expect(detect("15px")).to eq("number")
    end

    it "unquoted string --> string" do
      expect(detect("bold")).to eq("string")
    end
    it "quoted string --> string" do
      expect(detect('"blah blah"')).to eq("string")
    end

    it "color name --> color" do
      expect(detect("orange")).to eq("color")
    end
    it "color code --> color" do
      expect(detect("#ff00cc")).to eq("color")
    end
    it "rgba() --> color" do
      expect(detect("rgba(255, 0, 0, 0.5)")).to eq("color")
    end
    it "hsl() --> color" do
      expect(detect("hsl(0, 100%, 50%)")).to eq("color")
    end
    it "fade-in() --> color" do
      expect(detect("fade-in(#cc00cc, 0.2)")).to eq("color")
    end

    it "true --> boolean" do
      expect(detect("true")).to eq("boolean")
    end
    it "false --> boolean" do
      expect(detect("false")).to eq("boolean")
    end

    it "comma-separated list --> list" do
      expect(detect("'Arial', Verdana, sans-serif")).to eq("list")
    end
    it "space-separated list --> list" do
      expect(detect("2px 4px 2px 4px")).to eq("list")
    end

    it "null --> nil" do
      expect(detect("null")).to eq(nil)
    end
  end

end
