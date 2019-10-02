# -*- coding: utf-8 -*-
require "jsduck/format/shortener"

describe JsDuck::Format::Shortener do

  describe "#shorten" do

    def shorten(text)
      JsDuck::Format::Shortener.new(10).shorten(text)
    end

    it "appends ellipsis to short text" do
      expect(shorten("Ha ha")).to eq("Ha ha ...")
    end

    it "shortens text longer than max length" do
      expect(shorten("12345678901")).to eq("1234567...")
    end

    it "counts multi-byte characters correctly when measuring text length" do
      # Text ending with a-umlaut character
      expect(shorten("123456789ä")).to eq("123456789ä ...")
    end

    it "shortens text with multi-byte characters correctly" do
      # Text containing a-umlaut character
      expect(shorten("123456ä8901")).to eq("123456ä...")
    end

    it "strips HTML tags when shortening" do
      expect(shorten("<a href='some-long-link'>12345678901</a>")).to eq("1234567...")
    end

    it "takes only first centence" do
      expect(shorten("bla. blah")).to eq("bla. ...")
    end
  end

  describe "#too_long?" do

    def too_long?(text)
      JsDuck::Format::Shortener.new(10).too_long?(text)
    end

    it "is false when exactly equal to the max_length" do
      expect(too_long?("1234567890")).to eq(false)
    end

    it "is false when short sentence" do
      expect(too_long?("bla bla.")).to eq(false)
    end

    it "is true when long sentence" do
      expect(too_long?("bla bla bla.")).to eq(true)
    end

    it "ignores HTML tags when calculating text length" do
      expect(too_long?("<a href='some-long-link'>Foo</a>")).to eq(false)
    end

    it "counts multi-byte characters correctly" do
      # Text ending with a-umlaut character
      expect(too_long?("123456789ä")).to eq(false)
    end
  end


  describe "#first_sentence" do
    def first_sentence(text)
      JsDuck::Format::Shortener.new.first_sentence(text)
    end

    it "extracts first sentence" do
      expect(first_sentence("Hi John. This is me.")).to eq("Hi John.")
    end
    it "extracts first sentence of multiline text" do
      expect(first_sentence("Hi\nJohn.\nThis\nis\nme.")).to eq("Hi\nJohn.")
    end
    it "returns everything if no dots in text" do
      expect(first_sentence("Hi John this is me")).to eq("Hi John this is me")
    end
    it "returns everything if no dots in text" do
      expect(first_sentence("Hi John this is me")).to eq("Hi John this is me")
    end
    it "ignores dots inside words" do
      expect(first_sentence("Hi John th.is is me")).to eq("Hi John th.is is me")
    end
    it "ignores first empty sentence" do
      expect(first_sentence(". Hi John. This is me.")).to eq(". Hi John.")
    end
    it "understands chinese/japanese full-stop character as end of sentence" do
      expect(first_sentence("Some Chinese Text。 And some more。")).to eq("Some Chinese Text。")
    end
  end

end
