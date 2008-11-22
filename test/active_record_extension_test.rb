require File.join(File.dirname(__FILE__), 'test_helper')

class ActiveRecordExtensionTest < ActiveSupport::TestCase
  class TestBase
    def self.belongs_to(association_id, options = {}, &block); end
    def self.before_save(*callbacks); end
    def self.after_save(*callacks); end

    include CachedAssociationAttributes::ActiveRecordExtension
  end
  
  test '#belongs_to_with_cached_association_attributes_options should delegate to #belongs_to_without_cached_association_attributes_options' do
    options = {:option_1 => 1, :options_2 => 2, :cached_attributes => [:attr]}
    
    reflection_stub = stub(:klass => TestBase)
    TestBase.expects(:belongs_to_without_cached_association_attributes_options).with(:association_id, options.except(:cached_attributes))
    TestBase.stubs(:reflect_on_association).returns(reflection_stub)
    
    TestBase.belongs_to_with_cached_association_attributes_options(:association_id, options)
  end
  
  test '#belongs_to_with_cached_association_attributes_options should not modify options' do
    options = {:option_1 => 1, :options_2 => 2, :cached_attributes => [:attr]}
    old_options = options.dup
    
    reflection_stub = stub(:klass => TestBase)
    TestBase.stubs(:reflect_on_association).returns(reflection_stub)
    
    TestBase.belongs_to_with_cached_association_attributes_options(:association_id, options)

    assert_equal old_options, options
  end  
end
