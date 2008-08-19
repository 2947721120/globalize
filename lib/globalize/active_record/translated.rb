module Globalize
  module ActiveRecord
    module Translated

      def self.included(base)
        base.extend ActMethods
      end
            
      module ActMethods
        def translates(*options)
          proxy_records = "#{name.underscore}_translations".intern
          
          # Only include once per class
          unless included_modules.include? InstanceMethods
            class_inheritable_accessor :options
            extend ClassMethods
            include InstanceMethods
             
            create_proxy_class
            has_many proxy_records do
              def current_locale
                find_by_locale I18n.locale
              end
            end
          end
          self.options = options

          proxy_association = :"#{name.underscore}_translations"
          self.options.each do |attr_name|
            iv = "@#{attr_name}"
            define_method attr_name, lambda {
              instance_variable_get(iv) || instance_variable_set(iv, 
                send(proxy_association).current_locale.send(attr_name))
            }
            define_method "#{attr_name}=", lambda {|val|
              instance_variable_set iv, val
            }
          end 

        end

        private
        
        def create_ar_class(class_name, &block)
          klass = Class.new ::ActiveRecord::Base, &block
          Object.const_set class_name, klass
        end
        
        def create_proxy_class
          original_class_name = name
          create_ar_class "#{name}Translation" do
            belongs_to "#{original_class_name.underscore}".intern
          end
        end

      end
      
      module InstanceMethods
      end
  
      module ClassMethods
      end       
      
    end      
  end
end
