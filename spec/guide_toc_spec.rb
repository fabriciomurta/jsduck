# -*- coding: utf-8 -*-
require "jsduck/guide_toc"

describe JsDuck::GuideToc do

  def inject(html)
    JsDuck::GuideToc.new(html, "myguide", max_level).inject!
  end

  describe "With max_level=1" do
    let(:max_level) { 2 }

    it "adds no toc section even when many H1 headings" do
      expect(inject(<<-EOHTML)).not_to match(/<div class='toc'>/)
        <h1>Chapter A</h2>
        <h1>Chapter B</h2>
        <h1>Chapter C</h2>
      EOHTML
    end
  end

  describe "With max_level=2" do
    let(:max_level) { 2 }

    it "adds no toc section when no headings" do
      expect(inject("blah")).not_to match(/<div class='toc'>/)
    end

    it "adds no toc section when less than two H2 headings" do
      expect(inject(<<-EOHTML)).not_to match(/<div class='toc'>/)
        <h2>Chapter A</h2>
      EOHTML
    end

    it "adds toc section when at least two H2 headings" do
      expect(inject(<<-EOHTML)).to match(/<div class='toc'>/)
        <h2>Chapter A</h2>
        <h2>Chapter B</h2>
      EOHTML
    end

    it "adds ID-s to H2 headings" do
      expect(inject(<<-EOHTML)).to match(/<h2 id='myguide-section-my-chapter'>My Chapter/)
        <h2>My Chapter</h2>
        <h2>Another Chapter</h2>
      EOHTML
    end

    it "URL-encodes unicode in heading ID-s" do
      expect(inject(<<-EOHTML)).to match(/<h2 id='myguide-section-my-f%C3%A4pter'>My Fäpter/)
        <h2>My Fäpter</h2>
      EOHTML
    end

    it "links to headings from TOC" do
      expect(inject(<<-EOHTML)).to match(/<a href='#!\/guide\/myguide-section-my-chapter'>/)
        <h2>My Chapter</h2>
        <h2>Another Chapter</h2>
      EOHTML
    end

    it "links to unicode headings from TOC" do
      expect(inject(<<-EOHTML)).to match(/<a href='#!\/guide\/myguide-section-my-f%C3%A4pter'>/)
        <h2>My Fäpter</h2>
        <h2>Another Fäpter</h2>
      EOHTML
    end

    it "adds ID-s to H2 headings even when no TOC" do
      expect(inject(<<-EOHTML)).to match(/<h2 id='myguide-section-my-chapter'>My Chapter/)
        <h2>My Chapter</h2>
      EOHTML
    end

    it "keeps HTML in headings" do
      expect(inject(<<-EOHTML)).to match(/<h2 id='myguide-section-my-chapter'>My <span>Chapter<\/span>/)
        <h2>My <span>Chapter</span></h2>
      EOHTML
    end

    it "strips HTML from TOC entries" do
      expect(inject(<<-EOHTML)).to match(/<a href='#!\/guide\/myguide-section-my-chapter-1'>My Chapter/)
        <h2>My <span>Chapter</span> 1</h2>
        <h2>My <span>Chapter</span> 2</h2>
      EOHTML
    end

    it "adds ID-s also all H* headings" do
      expect(inject(<<-EOHTML)).to match(/<h5 id='myguide-section-my-chapter'>My Chapter/)
        <h5>My Chapter</h5>
      EOHTML
    end

    it "doesn't include any other headings besides H2 to TOC" do
      expect(inject(<<-EOHTML)).not_to match(/<a href='#!\/guide\/myguide-section-my-chapter'>/)
        <h3>My Chapter</h3>
        <h5>Another Chapter</h5>
      EOHTML
    end
  end

  describe "With max_level=3" do
    let(:max_level) { 3 }

    it "adds TOC when one H2 heading and one H3 heading" do
      expect(inject(<<-EOHTML)).to match(/<div class='toc'>/)
        <h2>Chapter A</h2>
        <h3>Chapter A.A</h3>
      EOHTML
    end

    it "adds TOC when two H3 headings" do
      expect(inject(<<-EOHTML)).to match(/<div class='toc'>/)
        <h3>Chapter A.A</h3>
        <h3>Chapter A.B</h3>
      EOHTML
    end

    it "links H3 heading from TOC" do
      expect(inject(<<-EOHTML)).to match(/<a href='#!\/guide\/myguide-section-h3-chapter'>/)
        <h2>My Chapter</h2>
        <h3>H3 Chapter</h3>
      EOHTML
    end

    it "doesn't include any other headings besides H2 and H3 to TOC" do
      expect(inject(<<-EOHTML)).not_to match(/<a href='#!\/guide\/myguide-section-my-chapter'>/)
        <h2>Foo</h2>
        <h3>Bar</h3>
        <h4>My Chapter</h4>
        <h5>Another Chapter</h5>
      EOHTML
    end
  end

end
