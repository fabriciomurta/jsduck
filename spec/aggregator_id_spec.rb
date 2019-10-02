require "mini_parser"

describe JsDuck::Aggregator do
  def parse(string)
    Helper::MiniParser.parse(string)
  end

  def parse_id(string)
    parse(string)["global"][:members][0][:id]
  end

  it "event foo gets id event-foo" do
    id = parse_id(<<-EOF)
      /**
       * @event foo
       */
    EOF
    expect(id).to eq("event-foo")
  end

  it "config foo gets id cfg-foo" do
    id = parse_id(<<-EOF)
      /**
       * @cfg {String} foo
       */
    EOF
    expect(id).to eq("cfg-foo")
  end

  it "static property foo gets id static-property-foo" do
    id = parse_id(<<-EOF)
      /**
       * @property {String} foo
       * @static
       */
    EOF
    expect(id).to eq("static-property-foo")
  end

  it "static method foo gets id static-method-foo" do
    id = parse_id(<<-EOF)
      /**
       * @method foo
       * @static
       */
    EOF
    expect(id).to eq("static-method-foo")
  end

end
