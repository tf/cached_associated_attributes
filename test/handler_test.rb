require File.join(File.dirname(__FILE__), 'test_helper')

class ActiveRecordExtensionTest < ActiveSupport::TestCase
  test '#synchronize should only load association if foreign key changed' do
    handler = CachedAssociationAttributes::Handler.new(stub_owner, stub_reflection, [:name])
    model = stub_model

    model.stubs(:user_id_changed?).returns(false)
    model.expects(:user).never
    handler.synchronize(model)
    
    model.stubs(:user_id_changed?).returns(true)
    model.expects(:user).once.returns(stub_target)
    handler.synchronize(model)
  end
  
  test '#synchronize should reload association if foreign key does not match target id' do
    handler = CachedAssociationAttributes::Handler.new(stub_owner, stub_reflection, [:name])
    model = stub_model
    target = stub_target(:id => 1)
    
    model.stubs(:user).returns(target)
    model.stubs(:user_id).returns(2)
    target.expects(:reload)
    handler.synchronize(model)

    model.stubs(:user_id).returns(nil)
    target.expects(:reload)
    handler.synchronize(model)

    model.stubs(:user).returns(nil)
    model.stubs(:user_id).returns(1)
    handler.synchronize(model)
  end

  test '#synchronize should refresh cache attribute' do
    handler = CachedAssociationAttributes::Handler.new(stub_owner, stub_reflection, [:name])
    model = stub_model
    
    target = stub_target(:name => 'Tom')
    model.stubs(:user).returns(target)
    model.expects(:user_name=).with('Tom')
    handler.synchronize(model)
    
    model.stubs(:user).returns(nil)
    model.expects(:user_name=).with(nil)
    handler.synchronize(model)
  end
  
  test '#update_all should update changed attributes' do
    owner = stub_owner
    handler = CachedAssociationAttributes::Handler.new(owner, stub_reflection, [:name, :email])
    
    model = stub_model()
    target = stub_target(:id => 1, :name => 'Tom', :name_changed? => false, :email => 'tom@example.com', :email_changed? => true)
    owner.expects(:update_all).with({:user_email => 'tom@example.com'}, {:user_id => 1})
    handler.update_all(target)    
  end
  
  test '#update_all should not update when there are no changes' do
    owner = stub_owner
    handler = CachedAssociationAttributes::Handler.new(owner, stub_reflection, [:name, :email])
    
    model = stub_model()
    target = stub_target(:id => 1, :name => 'Tom', :name_changed? => false, :email => 'tom@example.com', :email_changed? => false)
    owner.expects(:update_all).never
    handler.update_all(target)    
  end
  
  test '#update_all should update attributes without _changed? method' do
    owner = stub_owner
    handler = CachedAssociationAttributes::Handler.new(owner, stub_reflection, [:full_name])
    
    model = stub_model()
    target = stub_target(:id => 1, :full_name => 'John Doe')
    target.stubs(:full_name_changed?).raises(NoMethodError)
    owner.expects(:update_all).with({:user_full_name => 'John Doe'}, {:user_id => 1})
    handler.update_all(target)    
  end
  
  private
  
  def stub_owner(attr = {})
    stub('owner', attr.reverse_merge({}))
  end
  
  def stub_model(attr = {})
    stub('model', attr.reverse_merge(:user => stub_target, :user_id => 1, :user_id_changed? => true, :user_name= => ''))
  end
  
  def stub_reflection(attr = {})
    stub('reflection', attr.reverse_merge(:name => :user, :klass => nil, :primary_key_name => :user_id))
  end
  
  def stub_target(attr = {})
    stub('target', attr.reverse_merge(:id => 1, :name => 'Lisa'))
  end
end
