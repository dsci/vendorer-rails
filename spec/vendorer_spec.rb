require 'spec_helper'

describe Vendorer do
  before do
    `rm -rf spec/tmp`
    `mkdir spec/tmp`
  end

  after do
    `rm -rf spec/tmp`
  end

  def write(file, content)
    File.open("spec/tmp/#{file}",'w'){|f| f.write(content) }
  end

  def read(file)
    File.read("spec/tmp/#{file}")
  end

  def size(file)
    File.size("spec/tmp/#{file}")
  end

  def ls(path)
    `ls spec/tmp/#{path} 2>&1`.split("\n")
  end

  def run(args='', options={})
    out = `cd spec/tmp && bundle exec ../../bin/vendorer #{args} 2>&1`
    raise out if $?.success? == !!options[:raise]
    out
  end

  describe 'version' do
    it "has a VERSION" do
      Vendorer::VERSION.should =~ /^[\.\da-z]+$/
    end

    it "shows its version via -v" do
      run('-v').should == "#{Vendorer::VERSION}\n"
    end

    it "shows its version via --version" do
      run('--version').should == "#{Vendorer::VERSION}\n"
    end
  end

  describe 'help' do
    it "shows help via -h" do
      run('-h').should include("Usage")
    end

    it "shows help via --help" do
      run('--help').should include("Usage")
    end
  end

  describe '.file' do
    context "with working Vendorfile" do
      before do
        write 'Vendorfile', "file 'public/javascripts/jquery.min.js', 'http://code.jquery.com/jquery-latest.min.js'"
        run
      end

      it "can download via hash syntax" do
        ls('public/javascripts').should == ["jquery.min.js"]
        read('public/javascripts/jquery.min.js').should include('jQuery')
      end

      it "does not update an existing file" do
        write('public/javascripts/jquery.min.js', 'Foo')
        run
        read('public/javascripts/jquery.min.js').should == 'Foo'
      end

      it "can update a file" do
        write('public/javascripts/jquery.min.js', 'Foo')
        run 'update'
        read('public/javascripts/jquery.min.js').should include('jQuery')
      end

      it "can update a single file" do
        write 'Vendorfile', "
          file 'public/javascripts/jquery.min.js', 'http://code.jquery.com/jquery-latest.min.js'
          file 'public/javascripts/jquery.js', 'http://code.jquery.com/jquery-latest.js'
        "
        run
        read('public/javascripts/jquery.js').should include('jQuery')
        read('public/javascripts/jquery.min.js').should include('jQuery')

        write('public/javascripts/jquery.js', 'Foo')
        write('public/javascripts/jquery.min.js', 'Foo')
        run 'update public/javascripts/jquery.js'
        size('public/javascripts/jquery.min.js').should == 3
        size('public/javascripts/jquery.js').should > 300
      end
    end

    it "fails with a nice message if the Vendorfile is broken" do
      write 'Vendorfile', "file 'xxx.js', 'http://NOTFOUND'"
      result = run '', :raise => true
      # different errors on travis / local
      raise result unless result.include?("resolve host 'NOTFOUND'") or result.include?('Downloaded empty file')
    end

    context "with a passed block" do
      before do
        write 'Vendorfile', "file('public/javascripts/jquery.js', 'http://code.jquery.com/jquery-latest.js'){|path| puts 'THE PATH IS ' + path }"
        @output = "THE PATH IS public/javascripts/jquery.js"
      end

      it "runs the block after update" do
        run.should include(@output)
      end

      it "does not run the block when not updating" do
        run
        run.should_not include(@output)
      end
    end
  end

  describe '.plugin' do
    it "can download via hash syntax" do
      write 'Vendorfile', "plugin 'vendor/plugins/parallel_tests', 'https://github.com/grosser/parallel_tests.git'"
      run
      ls('vendor/plugins').should == ["parallel_tests"]
      read('vendor/plugins/parallel_tests/Gemfile').should include('parallel')
    end

    it "reports errors when the Vendorfile is broken" do
      write 'Vendorfile', "plugin 'vendor/plugins/parallel_tests', 'https://blob'"
      output = run '', :raise => true
      # different errors on travis / local
      raise unless output.include?('Connection refused') or output.include?('resolve host')
    end

    context "with a fast,local repository" do
      before do
        write 'Vendorfile', "plugin 'its_recursive', '../../.git'"
        run
      end

      it "can download" do
        ls('').should include "its_recursive"
        ls('').should include "Vendorfile"
        read('its_recursive/Gemfile').should include('rake')
      end

      it "does not keep .git folder so everything can be checked in" do
        #ls('its_recursive/.git').first.should include('cannot access')
        ls('its_recursive/.git').first.should include('No such file or directory')
      end

      it "does not update an existing folder" do
        write('its_recursive/Gemfile', 'Foo')
        run
        read('its_recursive/Gemfile').should == 'Foo'
      end

      it "can update a plugin" do
        write('its_recursive/Gemfile', 'Foo')
        run 'update'
        read('its_recursive/Gemfile').should include('rake')
      end

      it "can update a single file" do
        write 'Vendorfile', "
          plugin 'its_recursive', '../../.git'
          plugin 'its_really_recursive', '../../.git'
        "
        run
        write('its_recursive/Gemfile', 'Foo')
        write('its_really_recursive/Gemfile', 'Foo')
        run 'update its_recursive'
        size('its_really_recursive/Gemfile').should == 3
        size('its_recursive/Gemfile').should > 30
      end
    end

    describe "git options" do
      it "can checkout by :ref" do
        write 'Vendorfile', "plugin 'its_recursive', '../../.git', :ref => 'b1e6460'"
        run
        read('its_recursive/Readme.md').should include('CODE EXAMPLE')
      end

      it "can checkout by :branch" do
        write 'Vendorfile', "plugin 'its_recursive', '../../.git', :branch => 'b1e6460'"
        run
        read('its_recursive/Readme.md').should include('CODE EXAMPLE')
      end

      it "can checkout by :tag" do
        write 'Vendorfile', "plugin 'its_recursive', '../../.git', :tag => 'b1e6460'"
        run
        read('its_recursive/Readme.md').should include('CODE EXAMPLE')
      end
    end

    context "with a passed block" do
      before do
        write 'Vendorfile', "plugin('its_recursive', '../../.git'){|path| puts 'THE PATH IS ' + path }"
        @output = 'THE PATH IS its_recursive'
      end

      it "runs the block after update" do
        run.should include(@output)
      end

      it "does not run the block when not updating" do
        run
        run.should_not include(@output)
      end
    end
  end
end
