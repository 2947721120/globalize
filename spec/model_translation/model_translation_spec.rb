require File.dirname(__FILE__) + '/../spec_helper.rb'
require 'active_record'
require 'globalize/active_record/translated'

# Hook up model translation
ActiveRecord::Base.send(:include, Globalize::ActiveRecord::Translated)

require 'spec/helpers/active_record'
require 'factory_girl'
require 'spec/models/post'

  
describe Globalize::ActiveRecord::Translated, 'in the guise of a Post object' do
  include Spec::Matchers::HaveAttribute
  include Spec::Helpers::ActiveRecord  

  before do
    reset_db
  end
  
  it "has post_translations" do
    post = Post.create
    lambda { post.post_translations }.should_not raise_error
  end

  it "returns the value passed to :subject" do
    post = Post.new
    (post.subject = 'foo').should == 'foo'    
  end 

  it "translates subject and content into en-US" do
    post = Post.create :subject => 'foo', :content => 'bar'
    post.subject.should == 'foo' 
    post.content.should == 'bar'
    post.save.should == true 
    
    # This doesn't work yet, because we haven't done saving code
    post.reload
    post.subject.should == 'foo' 
    post.content.should == 'bar'
  end
  
  it "finds a post" do
    Factory :post
    lambda { Post.first }.should_not raise_error
    Post.first.subject.should == 'foo'
  end
end
