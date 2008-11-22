require 'cached_association_attributes/active_record_extension'
require 'cached_association_attributes/handler'

ActiveRecord::Base.send(:include, CachedAssociationAttributes::ActiveRecordExtension)

