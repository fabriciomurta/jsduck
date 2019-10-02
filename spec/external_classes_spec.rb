require "jsduck/external_classes"

describe JsDuck::ExternalClasses do

  before do
    @external = JsDuck::ExternalClasses.new(["Foo", "Ns.bar.Baz", "Bla.*"])
  end

  it "matches simple classname" do
    expect(@external.is?("Foo")).to eq(true)
  end

  it "matches namespaced classname" do
    expect(@external.is?("Ns.bar.Baz")).to eq(true)
  end

  it "doesn't match completely different classname" do
    expect(@external.is?("Zap")).not_to eq(true)
  end

  it "doesn't match classname beginning like an external classname" do
    expect(@external.is?("Foo.Bar")).not_to eq(true)
  end

  it "matches external classname defined with a wildcard" do
    expect(@external.is?("Bla.Bla")).to eq(true)
  end

  it "escapes '.' correctly in external pattern and doesn't match a classname missing the dot" do
    expect(@external.is?("Bla_Bla")).to eq(false)
  end

  it "doesn't match HTMLElement by default" do
    expect(@external.is?("HTMLElement")).to eq(false)
  end

  describe "with '@browser' in list of patterns" do
    before do
      @external.add("@browser")
    end

    it "doesn't match the special '@browser' pattern itself" do
      expect(@external.is?("@browser")).to eq(false)
    end

    # These classes were originally in the set of default externals.
    %w(
      HTMLElement
      HTMLDivElement
      XMLHttpRequest
      Window
      NodeList
      CSSStyleSheet
      CSSStyleRule
      Event
    ).each do |name|
      it "matches #{name}" do
        expect(@external.is?(name)).to eq(true)
      end
    end

  end

end
