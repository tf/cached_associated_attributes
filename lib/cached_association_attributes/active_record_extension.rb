module CachedAssociationAttributes
  module ActiveRecordExtension
    def self.included(base)
      base.extend(ClassMethods)
      base.metaclass.alias_method_chain :belongs_to, :cached_association_attributes_options
      
      base.class_inheritable_array :cached_association_attribute_pull_handlers
      base.cached_association_attribute_pull_handlers = []

      base.class_inheritable_array :cached_association_attribute_push_handlers
      base.cached_association_attribute_push_handlers = []
      
      base.before_save :pull_cached_association_attributes
      base.after_save :push_cached_association_attributes
    end

    protected
    
    def pull_cached_association_attributes
      cached_association_attribute_pull_handlers.each do |handler|
        handler.synchronize(self)
      end
    end
    
    def push_cached_association_attributes
      cached_association_attribute_push_handlers.each do |handler|
        handler.update_all(self)
      end
    end

    module ClassMethods
      def belongs_to_with_cached_association_attributes_options(association_id, options = {}, &block)
        options = options.dup
        cached_attributes = Array(options.delete(:cached_attributes))

        belongs_to_without_cached_association_attributes_options(association_id, options, &block)

        reflection = reflect_on_association(association_id)
        handler = Handler.new(self, reflection, cached_attributes)
        
        cached_association_attribute_pull_handlers << handler
        reflection.klass.cached_association_attribute_push_handlers << handler
      end
    end
  end
end
