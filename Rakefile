require 'rubygems'
require 'rake'
require 'time'

$LOAD_PATH.unshift File.expand_path("../lib", __FILE__)

require 'jsduck/util/md5'

def os_is_windows?
  # cygwin supports symlinks, but symlinks it makes are not usable by windows.
  RbConfig::CONFIG['host_os'] =~ /mswin|mingw|cygwin/
end

require 'rspec'
require 'rspec/core/rake_task'

desc "Runs RSpec testsuite (DEFAULT)"
RSpec::Core::RakeTask.new(:spec) do |spec|
  spec.rspec_opts = ["--color"] unless os_is_windows?
  spec.pattern = [
    "spec/spec_helper.rb",
    "spec/**/*_spec.rb",
  ]
end

def load_sdk_vars
  if File.exists?("sdk-vars.rb")
    require "./sdk-vars.rb"
  else
    puts "Error: sdk-vars.rb not found."
    puts
    puts "Please create file sdk-vars.rb and define in it:"
    puts
    puts "    # where to output the docs"
    puts "    OUT_DIR='/path/to/ouput/dir'"
    puts "    # path to Ext JS 4 build"
    puts "    EXT_BUILD='/path/to/ext-4'"
    puts "    # path to Touch 2 build (for building Sencha Touch)"
    puts "    TOUCH_BUILD='/path/to/touch-2'"
    puts "    # path to SDK (for developers at Sencha)"
    puts "    SDK_DIR='/path/to/SDK'"
    exit 1
  end
end

# Compress JS/CSS file in-place
# Using a hackish way to access yui-compressor
def yui_compress(fname)
  system "java -jar $(dirname $(which sencha))/bin/yuicompressor.jar -o #{fname} #{fname}"
end

def symlink_supported?
  File.symlink nil, nil
rescue NotImplementedError
  return false
rescue
  return true
end

# Reads in all CSS files referenced between BEGIN CSS and END CSS markers.
# Deletes those input CSS files and writes out concatenated CSS to
# resources/css/app.css
# Finally replaces the CSS section with <link> to that one CSS file.
def combine_css(html, dir)
  css_section_re = /<!-- BEGIN CSS -->.*<!-- END CSS -->/m
  css = []
  css_section_re.match(html)[0].each_line do |line|
    if line =~ /<link rel="stylesheet" href="(.*?)"/
      file = $1
      css << IO.read(dir + "/" + file)
    end
  end

  fname = "#{dir}/resources/css/app.css"
  File.open(fname, 'w') {|f| f.write(css.join("\n")) }
  yui_compress(fname)
  fname = JsDuck::Util::MD5.rename(fname)

  html.sub(css_section_re, '<link rel="stylesheet" href="resources/css/' + File.basename(fname) + '" type="text/css" />')
end

# Same thing for JavaScript, result is written to: app.js
def combine_js(html, dir)
  js_section_re = /<!-- BEGIN JS -->.*<!-- END JS -->/m
  js = []
  js_section_re.match(html)[0].each_line do |line|
    if line =~ /<script .* src="(.*)">/
      file = $1
      js << IO.read(dir + "/" + file)
    elsif line =~ /<script .*>(.*)<\/script>/
      js << $1
    end
  end

  fname = "#{dir}/app.js"

  File.open(fname, 'w') {|f| f.write(js.join("\n")) }
  yui_compress(fname)
  fname = JsDuck::Util::MD5.rename(fname)
  html.sub(js_section_re, '<script type="text/javascript" src="' + File.basename(fname) + '"></script>')
end

# Modifies HTML to link app.css.
def rewrite_css_links(dir, filename)
  html = IO.read(dir + "/" + filename);
  html = combine_css(html, dir)
  File.open(dir + "/" + filename, 'w') {|f| f.write(html) }
end

# Compress JavaScript and CSS files of JSDuck
def compress
  load_sdk_vars

  # Clean up template-min/ left over from previous compress task
  system("rm", "-rf", "template-min")
  # Copy template/ files to template-min/
  system("cp", "-r", "template", "template-min")
  # Now do everything that follows in template-min/ dir
  dir = "template-min"

  # Requires a working (and old) installation of Sencha CMD
  # Create JSB3 file for Docs app (no longer works)
  #system("sencha", "create", "jsb", "-a", "http://localhost/docs/", "-p", "#{dir}/app.jsb3")
  # Concatenate files listed in JSB3 file
  #system("sencha", "build", "-p", "#{dir}/app.jsb3", "-d", dir)

  # Remove intermediate build files
  #system("rm", "#{dir}/app.jsb3")
  system("rm", "#{dir}/all-classes.js")
  # Replace app.js with app-all.js
  system("mv", "#{dir}/app-all.js", "#{dir}/app.js")
  # Remove the entire app/ dir
  system("rm", "-r", "#{dir}/app")

  # Change CSS links in print-template.html and index-template.html files
  rewrite_css_links(dir, "print-template.html")
  rewrite_css_links(dir, "index-template.html")

  # Concatenate CSS and JS files referenced in template.html file
  template_html = "#{dir}/template.html"
  html = IO.read(template_html)
  html = combine_css(html, dir)
  html = combine_js(html, dir)
  File.open(template_html, 'w') {|f| f.write(html) }

  # Clean up SASS files
  # (But keep prettify lib, which is needed for source files)
  system "rm -rf #{dir}/resources/css/docs-ext.css"
  system "rm -rf #{dir}/resources/css/viewport.css"
  system "rm -rf #{dir}/resources/sass"
  system "rm -rf #{dir}/resources/codemirror"
  system "rm -rf #{dir}/resources/.sass-cache"

  # Empty the extjs dir, leave only the main JS file and images
  system "rm -rf #{dir}/extjs"
  system "mkdir #{dir}/extjs"
  system "cp template/extjs/ext-all.js #{dir}/extjs"
  system "mkdir -p #{dir}/extjs/resources/themes/images"
  system "cp -r template/extjs/resources/themes/images/default #{dir}/extjs/resources/themes/images"
end

class JsDuckRunner
  def initialize
    @options = []
    load_sdk_vars
  end

  def add_options(*options)
    @options += options
  end

  def get_options
    return @options
  end

  def add_comments(db_name, version)
    add_options("--comments-url", "http://localhost:3000/auth")
    add_options("--comments-domain", db_name+"/"+version)
  end

  def add_search(product, version)
    add_options("--search-url", "http://support-test.sencha.com:8080/docsearch/search")
    add_options("--search-domain", product+"/"+version)
  end

  def add_ext4
    @options += [
      "--title", "Sencha Docs - Ext JS 4.0",
      "--footer", "Ext JS 4.0 Docs - Generated with <a href='https://github.com/senchalabs/jsduck'>JSDuck</a> {VERSION}." +
                  " <a href='http://www.sencha.com/legal/terms-of-use/'>Terms of Use</a>",
      "--ignore-global",
      "--warnings", "-all",
      "--images", "#{EXT_BUILD}/docs/images",
      "--local-storage-db", "ext-4",
      "--output", "#{OUT_DIR}",
      "#{EXT_BUILD}/src",
    ]
  end

  def add_ext(toolkit, versn)
    if toolkit != "modern" && toolkit != "classic"
      tkpath = "packages/" + toolkit
    else
      tkpath = toolkit + "/" + toolkit
    end

    ext_build = EXT_6
    if versn == 7
      ext_build = EXT_7
    end

    @options += [
      "--title", "Sencha Docs - Ext JS #{versn} " + toolkit,
      "--footer", "Ext JS #{versn}/" + toolkit + " Docs - Generated with <a href='https://github.com/fabriciomurta/jsduck'>JSDuck</a> {VERSION}." +
                  " <a href='http://www.sencha.com/legal/terms-of-use/'>Terms of Use</a>",
      "--ignore-global",
      "--output", "#{OUT_DIR}/ext#{versn}_" + toolkit,
      ext_build + "/" + tkpath + "/src",
    ]
  end

  def add_enjs(versn)
    @options += [
      "--title", "Sencha Docs - Ext.NET #{versn} ",
      "--footer", "Ext.NET Docs - Generated with <a href='https://github.com/fabriciomurta/jsduck'>JSDuck</a> {VERSION}." +
                  " <a href='http://www.sencha.com/legal/terms-of-use/'>Terms of Use</a>",
      "--ignore-global",
      "--output", "#{OUT_DIR}/extnet#{versn}",
      "#{EXT_NET}",
    ]
  end

  # this is currently not version-bound, actually
  def add_ejsdebug(toolkit)
    add_options(
      "--extjs-path", "extjs/ext-all-debug.js",
      "--template", "template"
    )

    tpldir = "template/extjs"
    #symlinktarget = EXT_BUILD + "/build"
    #if (symlinktarget[0] != "/")
    #  symlinktarget="../" + symlinktarget
    #end

    #if File.exists?(tpldir)
    #  if symlink_supported? and File.symlink?(tpldir)
    #    if File.readlink(tpldir) != symlinktarget
    #      puts("Rake: removing old (wrong) symlink.")
    #      File.delete(tpldir)
    #    end
    #  else
    #    puts("Rake: removing old template/extjs directory")
    #    File.rename(tpldir, tpldir + Time.now.strftime("%Y%m%d%H%M%S"))
    #  end
    #end

    #if !File.exists?(tpldir)
    #  if symlink_supported?
    #    File.symlink(symlinktarget, tpldir)
    #  else
    #    raise("Rake: symlinking not supported. Refusing to copy the whole ExtJS built sources to '" + tpldir + "'.")
    #  end
    #end
    add_options("--template-links") unless os_is_windows?
  end

  def run
    # Pass multiple arguments to system, so we'll take advantage of the built-in escaping
    cmdrun = system(*["ruby", "bin/jsduck"].concat(@options))

    if (cmdrun == nil)
      puts "JSDuck executable cannot be located/executed."
      exit 1
    elsif (cmdrun == false)
      retstat = $?
      puts "JSDuck execution returned non-success status code #{retstat}."
      exit 1
    end
    puts "JSDuck execution finished successfully."
  end
end

# Download ExtJS into template/extjs
task :get_extjs do
  if Dir.exists?("template/extjs")
    puts "template/extjs directory already exist. remove it beforehand."
    exit(1)
  end

  # Found in radiusdesk sourceforge project's SVN history:
  # revision: https://sourceforge.net/p/radiusdesk/code/238/
  # url: https://sourceforge.net/p/radiusdesk/code/238/tree/extjs/ext-4.1.1a-gpl.zip?format=raw
  system "curl -o template/extjs.zip 'https://sourceforge.net/p/radiusdesk/code/238/tree/extjs/ext-4.1.1a-gpl.zip?format=raw'"

  system "unzip template/extjs.zip -d template/"
  system "mv template/ext-4.1.1a template/extjs"
  system "rm template/extjs.zip"
end

# Auto-generate sdk-vars.rb config file
task :config_file do
  if File.exists?("sdk-vars.rb")
    puts "sdk-vars.rb already exists. Keeping it."
  else
    puts "Generating sdk-vars.rb with the following content:"
    config = <<-EORUBY
# where to output the docs
OUT_DIR='#{Dir.pwd}/output'
# path to Ext JS 4 build
EXT_BUILD='#{Dir.pwd}/template/extjs'
    EORUBY
    puts
    puts config
    File.open("sdk-vars.rb", "w") {|h| h.write(config) }
  end
end

desc "Download ExtJS and initialize sdk-vars.rb config file"
task :configure => [:get_extjs, :config_file]

# Run compass to generate CSS files
task :sass do
  #system "compass compile --quiet template/resources/sass"
  system "compass compile --quiet template/resources/sass"
end

def write_version_file(version)
  File.open('./lib/jsduck/version.rb', 'w') do |f|
    f.write(<<-EORUBY)
# This file is updated by rake bump task.
# Do not edit by hand.
module JsDuck
  VERSION = "#{version}"
end
EORUBY
  end
end

def commit_version(version)
  system "git commit lib/jsduck/version.rb -m 'Up version to #{version}.'"
  puts "Creating tag v#{version}"
  system "git tag -a v#{version} -m 'Tagging #{version} release.'"
end

desc <<-EOTEXT
Bumps JSDuck patch version number up by one.
When old version was 1.2.2, new will be 1.2.3.

Alternatively sets the specified version, when invoked like:

    rake bump['1.2.3']

Also commits and tags the change in git.
EOTEXT
task :bump, :new_version do |t, args|
  require "./lib/jsduck/version.rb"

  if args[:new_version]
    new = args[:new_version]
    puts "Bumping version from #{JsDuck::VERSION} to #{new}"
    write_version_file(new)
    commit_version(new)
  else
    if JsDuck::VERSION =~ /\A([0-9]+)\.([0-9]+)\.([0-9]+)\z/
      new = "#{$1}.#{$2}.#{$3.to_i+1}"
      puts "Bumping version from #{JsDuck::VERSION} to #{new}"
      write_version_file(new)
      commit_version(new)
    else
      puts "Unable to automatically bump the version: #{JsDuck::VERSION}"
      exit 1
    end
  end
end

desc "Compresses the template to output smaller code"
task :compress => :sass do
  compress
end

desc "Build JSDuck gem"
task :gem => :compress do
  compress
  system "gem build jsduck.gemspec"
end

desc "Run JSDuck on Docs app itself"
task :docs do
  runner = JsDuckRunner.new
  runner.add_ext4
  runner.add_options(
    "--builtin-classes",
    "template/app"
  )
  runner.add_debug
  runner.run
end

desc "Run JSDuck on official Ext JS 4 build"
task :ext4 => :sass do
  runner = JsDuckRunner.new
  runner.add_ext4
  runner.add_debug
  runner.run

  system("ln -s #{EXT_BUILD} #{OUT_DIR}/extjs-build")
end

def do_extjs(toolkit, versn)
  puts "Building docs for ExtJS #{versn} - " + toolkit
  runner = JsDuckRunner.new
  runner.add_ext(toolkit, versn)
  runner.add_ejsdebug(toolkit)
  #puts runner.get_options().join(' ')
  runner.run

  #system("ln -s #{EXT_BUILD}/packages/core #{OUT_DIR}/extjs-build_" + toolkit)
  puts "Done building docs for ExtJS #{versn} - " + toolkit
end

def do_ejsver(versn)
  do_extjs("core", versn)
  do_extjs("classic", versn)
  do_extjs("modern", versn)
  puts "All Ext JS parts built."
end

desc "Run JSDuck on official Ext JS 6 build"
task :ext6 => [ :sass ] do
  do_ejsver(6)
end

desc "Run JSDuck on official Ext JS 7 build"
task :ext7 => [ :sass ] do
  do_ejsver(7)
end

desc "Run JSDuck on Ext.NET JavaScript sources"
task :extnet do
  puts "Building docs for Ext.NET 5 "
  runner = JsDuckRunner.new
  versn = 5
  runner.add_enjs(versn)

  runner.add_ejsdebug("classic")
  runner.run

  #system("ln -s #{EXT_BUILD}/packages/core #{OUT_DIR}/extjs-build_" + toolkit)
  puts "Done building docs for ExtJS #{versn} - " + toolkit
end

task :default => :spec
