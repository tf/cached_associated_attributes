ActiveRecord::Base.logger = Logger.new(File.join(File.dirname(__FILE__), "debug.log"))
ActiveRecord::Base.establish_connection(
  :adapter => 'sqlite3',
  :database => ':memory:'
)
 
class CreateSchema < ActiveRecord::Migration
  def self.up
    create_table :users, :force => true do |t|
      t.string :name
      t.string :email
      t.integer :post_count
    end
 
    create_table :posts, :force => true do |t|
      t.string  :name
      t.integer :author_id
      t.string  :author_name
      t.string  :author_email
      t.integer :user_id
      t.string  :user_name
      t.integer :user_post_count
      t.integer :custom_key
      t.string :owner_name
    end
  end
end
 
CreateSchema.suppress_messages { CreateSchema.migrate(:up) }
 

