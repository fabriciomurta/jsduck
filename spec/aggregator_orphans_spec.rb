require "mini_parser"

describe JsDuck::Aggregator do

  def parse(string)
    Helper::MiniParser.parse(string)
  end

  shared_examples_for "class of orphans" do
    it "results in one class" do
      expect(@classes.length).to eq(1)
    end

    it "combines members into itself" do
      expect(@classes[@classname][:members].length).to eq(2)
    end

    it "preserves the order of members" do
      ms = @classes[@classname][:members]
      expect(ms[0][:name]).to eq("foo")
      expect(ms[1][:name]).to eq("bar")
    end
  end

  describe "class named by orphan members" do
    before do
      @classname = "MyClass"
      @classes = parse(<<-EOS)
        /**
         * @method foo
         * @member MyClass
         */
        /**
         * @method bar
         * @member MyClass
         */
      EOS
    end

    it_should_behave_like "class of orphans"
  end

  describe "orphan members without @member" do
    before do
      @classname = "global"
      @classes = parse(<<-EOS)
        /**
         * @method foo
         */
        /**
         * @method bar
         */
      EOS
    end

    it "results in global class" do
      expect(@classes["global"][:name]).to eq("global")
    end

    it_should_behave_like "class of orphans"
  end
end
