# -*- coding: utf-8 -*-
require "jsduck/guide_anchors"

describe JsDuck::GuideAnchors do

  def transform(html)
    JsDuck::GuideAnchors.transform(html, "myguide")
  end

  it "transforms anchor links" do
    expect(transform("<a href='#blah'>label</a>")).to eq(
      "<a href='#!/guide/myguide-section-blah'>label</a>"
    )
  end

  it "transforms anchor links in fuzzier HTML" do
    expect(transform("<a\n class='blah' href=\"#blah\"\n>label</a>")).to eq(
      "<a\n class='blah' href=\"#!/guide/myguide-section-blah\"\n>label</a>"
    )
  end

  it "transforms anchor links in longer HTML" do
    expect(transform("Some\nlong\ntext\nhere...\n\n <a href='#blah'>label</a>")).to eq(
      "Some\nlong\ntext\nhere...\n\n <a href='#!/guide/myguide-section-blah'>label</a>"
    )
  end

  it "URL-encodes unicode anchors links" do
    expect(transform("<a href='#fäg'>label</a>")).to eq(
      "<a href='#!/guide/myguide-section-f%C3%A4g'>label</a>"
    )
  end

  it "doesn't transform normal links" do
    expect(transform("<a href='http://example.com'>label</a>")).to eq(
      "<a href='http://example.com'>label</a>"
    )
  end

  it "doesn't transform docs-app #! links" do
    expect(transform("<a href='#!/api/Ext.Base'>Ext.Base</a>")).to eq(
      "<a href='#!/api/Ext.Base'>Ext.Base</a>"
    )
  end

  it "doesn't transform docs-app (backwards-compatible) # links" do
    expect(transform("<a href='#/api/Ext.Base'>Ext.Base</a>")).to eq(
      "<a href='#/api/Ext.Base'>Ext.Base</a>"
    )
  end

  it "transforms anchors" do
    expect(transform("<a name='blah'>target</a>")).to eq(
      "<a name='myguide-section-blah'>target</a>"
    )
  end

  it "URL-encodes unicode in anchors" do
    expect(transform("<a name='fäg'>target</a>")).to eq(
      "<a name='myguide-section-f%C3%A4g'>target</a>"
    )
  end

  it "doesn't transform anchors already in target format" do
    expect(transform("<a name='myguide-section-blah'>target</a>")).to eq(
      "<a name='myguide-section-blah'>target</a>"
    )
  end

  it "transforms ID-s" do
    expect(transform("<h1 id='blah'>target</h1>")).to eq(
      "<h1 id='myguide-section-blah'>target</h1>"
    )
  end

  it "URL-encodes unicode in ID-s" do
    expect(transform("<h1 id='fäg'>target</h1>")).to eq(
      "<h1 id='myguide-section-f%C3%A4g'>target</h1>"
    )
  end

  it "doesn't transform ID-s already in target format" do
    expect(transform("<h1 id='myguide-section-blah'>target</h1>")).to eq(
      "<h1 id='myguide-section-blah'>target</h1>"
    )
  end

end
