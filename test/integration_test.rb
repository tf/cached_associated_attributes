require File.join(File.dirname(__FILE__), 'test_helper')

class IntegrationTest < ActiveSupport::TestCase
  class User < ActiveRecord::Base
    has_many :posts
    has_many :authored_posts, :foreign_key => :author_id, :class_name => 'Post'
    has_many :owned_posts, :foreign_key => :custom_key, :class_name => 'Post'
  end
  class Post < ActiveRecord::Base
    belongs_to :user, :cached_attributes => [:name, :post_count]
    belongs_to :author, :class_name => 'User', :cached_attributes => [:name, :email]
    belongs_to :owner, :foreign_key => :custom_key, :class_name => 'User', :cached_attributes => :name
  end
  
  test 'cached attribute synchronization' do
    post = Post.create
    
    assert_nil post.user_name
    assert_nil post.author_name
    assert_nil post.owner_name
    assert_nil post.author_email
    assert_nil post.user_post_count

    user = User.create(:name => 'John Doe', :email => 'john@example.com', :post_count => 5)

    post.update_attributes(:user => user)
    assert_equal 'John Doe', post.user_name
    assert_equal 5, post.user_post_count
    
    post.update_attributes(:author => user)
    assert_equal 'John Doe', post.author_name
    assert_equal 'john@example.com', post.author_email

    post.update_attributes(:owner => user)
    assert_equal 'John Doe', post.owner_name
    
    post = Post.create(:user => user, :author => user, :owner => user)    
    assert_equal 'John Doe', post.user_name
    assert_equal 'John Doe', post.author_name
    assert_equal 'John Doe', post.owner_name
    assert_equal 'john@example.com', post.author_email
    assert_equal 5, post.user_post_count
    
    post.update_attributes(:user => nil, :author => nil, :owner => nil)
    
    assert_nil post.user_name
    assert_nil post.author_name
    assert_nil post.owner_name
    assert_nil post.author_email
    assert_nil post.user_post_count

    post = user.posts.create
    assert_equal 'John Doe', post.user_name
    assert_equal 5, post.user_post_count
    
    post = user.authored_posts.create
    assert_equal 'John Doe', post.author_name
    assert_equal 'john@example.com', post.author_email

    post = user.owned_posts.create
    assert_equal 'John Doe', post.owner_name
    
    post = user.posts.create
    user = User.create(:name => 'Bob', :email => 'bob@example.com', :post_count => 10)
    user.posts << post
    assert_equal 'Bob', post.user_name
    assert_equal 10, post.user_post_count
    
    post.user_id = nil
    post.save
    assert_nil post.user_name
    assert_nil post.user_post_count
  end

  test '#has_many with :update_cached_attributes option' do
    user1 = User.create(:name => 'John Doe')
    user2 = User.create(:name => 'Bob')
    
    3.times { user1.posts.create; user2.posts.create }

    user1.update_attribute(:name, 'Joe')
    user1.posts.each { |post| assert_equal 'Joe', post.user_name }
    user2.posts.each { |post| assert_equal 'Bob', post.user_name }
    
    post = Post.create
    user1.owned_posts << post
    user2.authored_posts << post
    
    assert_equal 'Joe', post.owner_name
    assert_equal 'Bob', post.author_name
    
    user1.update_attribute(:name, 'Alison')
    post.reload
    
    assert_equal 'Alison', post.owner_name
    assert_equal 'Bob', post.author_name
  end
end
