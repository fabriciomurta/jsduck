require "jsduck/class_name"

describe "JsDuck::ClassName#short" do

  def short(name)
    JsDuck::ClassName.short(name)
  end

  it "returns only the last part of full name in normal case" do
    expect(short("My.package.Cls")).to eq("Cls")
  end

  it "returns the whole name when it has no parts" do
    expect(short("Foo")).to eq("Foo")
  end

  it "returns the second part when full_name has two uppercase parts" do
    expect(short("Foo.Bar")).to eq("Bar")
  end

  it "returns two last parts when full name has three uppercase parts" do
    expect(short("My.Package.Cls")).to eq("Package.Cls")
  end

end
