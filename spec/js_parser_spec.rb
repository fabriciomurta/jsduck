require "jsduck/js/parser"

describe JsDuck::Js::Parser do

  def parse(input)
    JsDuck::Js::Parser.new(input).parse
  end

  describe "parsing invalid JavaScript" do
    it "causes JS syntax error with line number to be raised" do
      begin
        parse("if ( x \n } alert('Hello');")
      rescue
        expect($!.to_s).to eq("Invalid JavaScript syntax: Unexpected '}' on line 2")
      end
    end

    it "causes JS syntax error for unexpected end of file to be raised" do
      begin
        parse("if ( x ) alert( ")
      rescue
        expect($!.to_s).to eq("Invalid JavaScript syntax: Unexpected end of file")
      end
    end
  end

  describe "parsing two comments" do
    before do
      @docs = parse(<<-EOS)
        /* Hello world
        */

        // Another
      EOS
    end

    it "detects 1-based line number of comment on first line" do
      expect(@docs[0][:linenr]).to eq(1)
    end

    it "detects line number of second comment on 4th line" do
      expect(@docs[1][:linenr]).to eq(4)
    end
  end

  describe "parsing line comment" do
    before do
      @docs = parse("// Hello world")
    end

    it "results in plain comment" do
      expect(@docs[0][:type]).to eq(:plain_comment)
    end
  end

  describe "parsing block comment" do
    before do
      @docs = parse("/* Hello world */")
    end

    it "results in plain comment" do
      expect(@docs[0][:type]).to eq(:plain_comment)
    end

    it "doesn't strip anything from the beginning of comment" do
      expect(@docs[0][:comment]).to eq(" Hello world ")
    end
  end

  describe "parsing block comment beginning with /**" do
    before do
      @docs = parse("/** Hello world */")
    end

    it "results in doc comment" do
      expect(@docs[0][:type]).to eq(:doc_comment)
    end

    it "strips * at the beginning of comment" do
      expect(@docs[0][:comment]).to eq(" Hello world ")
    end
  end

  describe "parsing comment after function" do
    before do
      @docs = parse(<<-EOS)
        function a() {
        }
        // Function A
      EOS
    end

    it "detects no code associated with comment" do
      expect(@docs[0][:code]).to eq(nil)
    end
  end

  describe "parsing two comments each before function" do
    before do
      @docs = parse(<<-EOS)
        // Function A
        function a() {
        }
        // Function B
        function b() {
        }
      EOS
    end

    it "finds two comments" do
      expect(@docs.length).to eq(2)
    end

    it "detects first comment as belonging to first function" do
      expect(@docs[0][:comment]).to eq(" Function A")
      expect(@docs[0][:code]["type"]).to eq("FunctionDeclaration")
      expect(@docs[0][:code]["id"]["name"]).to eq("a")
    end

    it "detects second comment as belonging to second function" do
      expect(@docs[1][:comment]).to eq(" Function B")
      expect(@docs[1][:code]["type"]).to eq("FunctionDeclaration")
      expect(@docs[1][:code]["id"]["name"]).to eq("b")
    end
  end

  describe "parsing two block comments before one function" do
    before do
      @docs = parse(<<-EOS)
        /* Function A */
        /* Function B */
        function b() {
        }
      EOS
    end

    it "finds two comments" do
      expect(@docs.length).to eq(2)
    end

    it "detects no code associated with first comment" do
      expect(@docs[0][:code]).to eq(nil)
    end

    it "detects second comment as belonging to the function" do
      expect(@docs[1][:code]["type"]).to eq("FunctionDeclaration")
    end
  end

  describe "parsing three line comments before one function" do
    before do
      @docs = parse(<<-EOS)
        // Very
        // Long
        // Comment
        function b() {
        }
      EOS
    end

    it "finds one comment" do
      expect(@docs.length).to eq(1)
    end

    it "merges all the line-comments together" do
      expect(@docs[0][:comment]).to eq(" Very\n Long\n Comment")
    end

    it "detects the whole comment as belonging to the function" do
      expect(@docs[0][:code]["type"]).to eq("FunctionDeclaration")
    end
  end

  describe "parsing three separated line comments before one function" do
    before do
      @docs = parse(<<-EOS)
        // Three

        // Separate


        // Comments
        function b() {
        }
      EOS
    end

    it "gets treated as three separate comments" do
      expect(@docs.length).to eq(3)
    end
  end

  describe "parsing 2 x two line comments before one function" do
    before do
      @docs = parse(<<-EOS)
        // First
        // Comment for A
        function a() {
        }
        // Second
        // Comment for B
        function b() {
        }
      EOS
    end

    it "finds two comments" do
      expect(@docs.length).to eq(2)
    end

    it "merges first two line-comments together" do
      expect(@docs[0][:comment]).to eq(" First\n Comment for A")
    end

    it "merges second two line-comments together" do
      expect(@docs[1][:comment]).to eq(" Second\n Comment for B")
    end
  end

  describe "parsing a comment before inner function" do
    before do
      @docs = parse(<<-EOS)
        function x() {
            // Function A
            function a() {
            }
        }
      EOS
    end

    it "detects comment as belonging to the inner function" do
      expect(@docs[0][:code]["type"]).to eq("FunctionDeclaration")
      expect(@docs[0][:code]["id"]["name"]).to eq("a")
    end

    it "detects range" do
      expect(@docs[0][:code]["range"]).to eq([61, 89, 3])
    end
  end

  describe "parsing heavily nested comment" do
    before do
      @docs = parse(<<-EOS)
        (function () {
            if (true) {
            } else {
                var i;
                for (i=0; i<10; i++) {
                    // Function A
                    function a() {
                    }
                }
             }
        })();
      EOS
    end

    it "detects comment as belonging to the inner function" do
      expect(@docs[0][:code]["type"]).to eq("FunctionDeclaration")
      expect(@docs[0][:code]["id"]["name"]).to eq("a")
    end
  end

  describe "parsing comment before object property" do
    before do
      @docs = parse(<<-EOS)
          var x = {
              foo: 5,
              // Some docs
              bar: 5
          }
      EOS
    end

    it "detects comment as belonging to the second property" do
      expect(@docs[0][:code]["type"]).to eq("Property")
      expect(@docs[0][:code]["key"]["name"]).to eq("bar")
    end
  end

  describe "parsing comment immediately before object literal" do
    before do
      @docs = parse(<<-EOS)
          x = /* Blah */{};
      EOS
    end

    it "associates comment with the code" do
      expect(@docs[0][:comment]).to eq(" Blah ")
      expect(@docs[0][:code]["type"]).to eq("ObjectExpression")
    end
  end

  # Sparse arrays are perfectly valid in JavaScript.
  # Omitted array members are initialized to undefined.
  describe "parsing comment before a missing array member" do
    before do
      @docs = parse(<<-EOS)
          x = [5, /* Blah */, 6];
      EOS
    end

    it "associates comment with the next array member after that" do
      expect(@docs[0][:comment]).to eq(" Blah ")
      expect(@docs[0][:code]["value"]).to eq(6)
    end
  end

end
