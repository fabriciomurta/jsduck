require "jsduck/warning/registry"
require 'jsduck/warning/warn_exception'

describe JsDuck::Warning::Registry do
  let(:warnings) do
    JsDuck::Warning::Registry.new
  end

  let(:usual_warnings) do
    [:tag, :global, :link]
  end

  describe "by default" do
    it "has the usual warnings disabled" do
      usual_warnings.each do |type|
        expect(warnings.enabled?(type, "")).to eq(false)
      end
    end

    it "has the nodoc warning disabled" do
      expect(warnings.enabled?(:nodoc, "", [:class, :public])).to eq(false)
    end
  end

  describe "after enabling all warnings" do
    before do
      warnings.set(:all, true)
    end

    it "has the usual warnings enabled" do
      usual_warnings.each do |type|
        expect(warnings.enabled?(type, "")).to eq(true)
      end
    end

    it "has the nodoc warning enabled" do
      expect(warnings.enabled?(:nodoc, "", [:class, :public])).to eq(true)
    end
  end

  shared_examples_for "limited to a path" do
    it "has the :tag warning disabled for /other/path/file.js" do
      expect(warnings.enabled?(:tag, "/other/path/file.js")).to eq(false)
    end

    it "has the :tag warning enabled for /some/path/file.js" do
      expect(warnings.enabled?(:tag, "/some/path/file.js")).to eq(true)
    end

    it "has the :tag warning enabled for /within/some/path/file.js" do
      expect(warnings.enabled?(:tag, "/within/some/path/file.js")).to eq(true)
    end
  end

  describe "after enabling all warnings in /some/path" do
    before do
      warnings.set(:all, true, "/some/path")
    end

    it_should_behave_like "limited to a path"
  end

  describe "after enabling :tag warning in /some/path" do
    before do
      warnings.set(:tag, true, "/some/path")
    end

    it_should_behave_like "limited to a path"

    describe "and also enabling it in /other/path" do
      before do
        warnings.set(:tag, true, "/other/path")
      end

      it "has the :tag warning enabled for /some/path/file.js" do
        expect(warnings.enabled?(:tag, "/some/path/file.js")).to eq(true)
      end

      it "has the :tag warning enabled for /other/path/file.js" do
        expect(warnings.enabled?(:tag, "/other/path/file.js")).to eq(true)
      end
    end

    describe "and disabling it in /some/path/sub/path" do
      before do
        warnings.set(:tag, false, "/some/path/sub/path")
      end

      it "has the :tag warning enabled for /some/path/file.js" do
        expect(warnings.enabled?(:tag, "/some/path/file.js")).to eq(true)
      end

      it "has the :tag warning disabled for /some/path/sub/path/file.js" do
        expect(warnings.enabled?(:tag, "/some/path/sub/path/file.js")).to eq(false)
      end
    end
  end

  describe "after enabling :tag warning" do
    before do
      warnings.set(:tag, true)
    end

    it "has the :tag warning enabled for a @footag" do
      expect(warnings.enabled?(:tag, "foo.js", [:footag])).to eq(true)
    end

    describe "and disabling it for @footag and @bartag" do
      before do
        warnings.set(:tag, false, nil, [:footag, :bartag])
      end

      it "has the :tag warning disabled for a @footag" do
        expect(warnings.enabled?(:tag, "bar.js", [:footag])).to eq(false)
      end

      it "has the :tag warning disabled for a @bartag" do
        expect(warnings.enabled?(:tag, "bar.js", [:bartag])).to eq(false)
      end

      it "has the :tag warning still enabled for a @mytag" do
        expect(warnings.enabled?(:tag, "bar.js", [:mytag])).to eq(true)
      end

      describe "and enabling it for files in /foo/" do
        before do
          warnings.set(:tag, true, "/foo/")
        end

        it "has the :tag warning enabled for a @footag in /foo/" do
          expect(warnings.enabled?(:tag, "/foo/bar.js", [:footag])).to eq(true)
        end

        it "still has the :tag warning disabled for a @footag outside of /foo/" do
          expect(warnings.enabled?(:tag, "bar.js", [:footag])).to eq(false)
        end
      end
    end
  end

  describe "after enabling :nodoc warning" do
    before do
      warnings.set(:nodoc, true)
    end

    it "has the :nodoc warning enabled for a public class" do
      expect(warnings.enabled?(:nodoc, "foo.js", [:class, :public])).to eq(true)
    end

    it "has the :nodoc warning enabled for a private member" do
      expect(warnings.enabled?(:nodoc, "bar.js", [:member, :private])).to eq(true)
    end

    describe "and disabling it for private members" do
      before do
        warnings.set(:nodoc, false, nil, [:member, :private])
      end

      it "has the :nodoc warning disabled for a private member" do
        expect(warnings.enabled?(:nodoc, "bar.js", [:member, :private])).to eq(false)
      end

      it "still has the :nodoc warning enabled for public members" do
        expect(warnings.enabled?(:nodoc, "bar.js", [:member, :public])).to eq(true)
      end

      describe "and enabling it for files in /foo/" do
        before do
          warnings.set(:nodoc, true, "/foo/", [:member, :private])
        end

        it "has the :nodoc warning enabled for a private member in /foo/bar.js" do
          expect(warnings.enabled?(:nodoc, "/foo/bar.js", [:member, :private])).to eq(true)
        end

        it "still has the :nodoc warning disabled in private member of /blah/foo.js" do
          expect(warnings.enabled?(:nodoc, "/blah/foo.js", [:member, :private])).to eq(false)
        end
      end
    end
  end

  describe "after +nodoc(class,public) and -all:blah/" do
    before do
      warnings.set(:nodoc, true, nil, [:class, :public])
      warnings.set(:all, false, "blah/")
    end

    it "has the :nodoc warning disabled for a public class in blah/" do
      expect(warnings.enabled?(:nodoc, "blah/foo.js", [:class, :public])).to eq(false)
    end
  end


  describe "for backwards compatibility" do
    describe ":no_doc warning" do
      before do
        begin
          warnings.set(:no_doc, true)
        rescue JsDuck::Warning::WarnException => e
          # Warning message for a deprecated warning is to be expected.
        end
      end

      it "enables :nodoc warnings for public classes" do
        expect(warnings.enabled?(:nodoc, "", [:class, :public])).to eq(true)
        expect(warnings.enabled?(:nodoc, "", [:class, :private])).to eq(false)
        expect(warnings.enabled?(:nodoc, "", [:member, :public])).to eq(false)
        expect(warnings.enabled?(:nodoc, "", [:param, :public])).to eq(false)
      end
    end

    describe ":no_doc_member warning" do
      before do
        begin
          warnings.set(:no_doc_member, true)
        rescue JsDuck::Warning::WarnException => e
          # Warning message for a deprecated warning is to be expected.
        end
      end

      it "enables :nodoc warnings for public members" do
        expect(warnings.enabled?(:nodoc, "", [:member, :public])).to eq(true)
        expect(warnings.enabled?(:nodoc, "", [:member, :private])).to eq(false)
        expect(warnings.enabled?(:nodoc, "", [:class, :public])).to eq(false)
        expect(warnings.enabled?(:nodoc, "", [:param, :public])).to eq(false)
      end
    end

    describe ":no_doc_param warning" do
      before do
        begin
          warnings.set(:no_doc_param, true)
        rescue JsDuck::Warning::WarnException => e
          # Warning message for a deprecated warning is to be expected.
        end
      end

      it "enables :nodoc warnings public params" do
        expect(warnings.enabled?(:nodoc, "", [:param, :public])).to eq(true)
        expect(warnings.enabled?(:nodoc, "", [:param, :private])).to eq(false)
        expect(warnings.enabled?(:nodoc, "", [:member, :public])).to eq(false)
        expect(warnings.enabled?(:nodoc, "", [:class, :public])).to eq(false)
      end
    end
  end

end
