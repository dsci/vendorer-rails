require 'spec_helper'

describe Vendorer do
  
  before do
    `rm -rf spec/tmp`
    `mkdir spec/tmp`
  end

  after do
    `rm -rf spec/tmp`
  end
  
  describe 'file or asset' do
    
    context "with working Vendorfile" do
      
      context "with rails project" do
        
        context ".asset" do 
        
          before do
            content = <<-VENDORFILE
                project :rails
          
                asset 'jquery.min.js', :source => 'http://code.jquery.com/jquery-latest.min.js'
              VENDORFILE
            write('Vendorfile',content)
            run ''
          end
          
          it "can download via hash syntax" do
            ls('app/assets/javascripts').should == ["jquery.min.js"]
            read('app/assets/javascripts/jquery.min.js').should include('jQuery')
          end
          
          it "does not update an existing asset file" do
            write('app/assets/javascripts/jquery.min.js', 'Foo')
            run
            read('app/assets/javascripts/jquery.min.js').should == 'Foo'
          end
          
          it "can update an asset file" do
            write('app/assets/javascripts/jquery.min.js', 'Foo')
            run 'update'
            read('app/assets/javascripts/jquery.min.js').should include('jQuery')
          end
          
          it "can update a single file" do
            content = <<-VENDORFILE
              project :rails
            
              asset 'jquery.min.js', :source => 'http://code.jquery.com/jquery-latest.min.js'
              asset 'jquery.js', :source => 'http://code.jquery.com/jquery-latest.js'
            VENDORFILE
            write('Vendorfile', content)
            run
            read('app/assets/javascripts/jquery.js').should include('jQuery')
            read('app/assets/javascripts/jquery.min.js').should include('jQuery')
  
            write('app/assets/javascripts/jquery.js', 'Foo')
            write('app/assets/javascripts/jquery.min.js', 'Foo')
            run 'update jquery.js'
            size('app/assets/javascripts/jquery.min.js').should == 3
            size('app/assets/javascripts/jquery.js').should > 300
          end
          
        
        end

      end
    end
  end
end