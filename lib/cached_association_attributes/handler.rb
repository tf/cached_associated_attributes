module CachedAssociationAttributes
  class Handler
    def initialize(owner, reflection, cached_attribute_names)
      @owner, @reflection, @cached_attribute_names = owner, reflection, cached_attribute_names
    end
    
    def synchronize(record)
      if association_changed?(record)
        ensure_association_reloaded(record)
        
        @cached_attribute_names.each do |attribute_name|
          value = association(record).send(attribute_name) rescue nil
          write_cache_attribute(record, attribute_name, value)
        end
      end
    end
    
    def update_all(target)
      assigns = update_assigns(target)
      @owner.update_all(assigns, foreign_key.to_sym => target.id) if assigns.any?
    end
  
    private

    def ensure_association_reloaded(record)
      association = association(record)
      if association && record.send(foreign_key) != association.id
        association.reload
      end
    end
    
    def update_assigns(target)
      @cached_attribute_names.inject({}) do |hash, attribute_name|  
        attribute_changed?(target, attribute_name) ? hash.merge(cache_attribute_name(attribute_name).to_sym => target.send(attribute_name)) : hash
      end
    end
      
    def association(record)
      record.send(association_name)
    end
    
    def association_name
      @reflection.name
    end
    
    def association_changed?(record)
      attribute_changed?(record, foreign_key)
    end
    
    def attribute_changed?(record, attribute_name)
      record.send("#{attribute_name}_changed?") rescue true
    end
    
    def foreign_key
      @reflection.primary_key_name
    end

    def write_cache_attribute(record, attribute_name, value)
      record.send("#{cache_attribute_name(attribute_name)}=", value)
    end
        
    def cache_attribute_name(attribute_name)
      "#{association_name}_#{attribute_name}"
    end
  end
end
