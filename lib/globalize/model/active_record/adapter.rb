module Globalize
  module Model
    class AttributeStash < Hash
      def read(locale, attr_name)
        self[locale] ||= {}
        self[locale][attr_name]
      end
      
      def write(locale, attr_name, value)
        self[locale] ||= {}
        self[locale][attr_name] = value
      end
    end
    
    class Adapter
      attr_reader :cache, :stash
      
      def initialize(record)
        @record = record
        @cache = AttributeStash.new
        @stash = AttributeStash.new
        @fallbacks = record.class.globalize_options[:fallbacks] || Globalize::Locale::Fallbacks.new
      end
      
      def fetch(locale, attr_name)
        locale = I18n.locale 
        cache.read(locale, attr_name) || begin
          val = fetch_attribute locale, attr_name
          cache.write locale, attr_name, val
        end
      end
      
      def update_translations!
        stash.each do |locale, attrs|
          translation = @record.globalize_translations.find_or_initialize_by_locale(locale)
          attrs.each{|attr_name, value| translation[attr_name] = value }
          translation.save!
        end
      end
      
      private
      
      def fetch_attribute(locale, attr_name)
        fallbacks = @fallbacks.compute locale
        translations = @record.globalize_translations.by_locales(fallbacks)
        result, requested_locale = nil, locale
      
        # Walk through the fallbacks, starting with the current locale itself, and moving
        # to the next best choice, until we find a match.
        # Check the @globalize_set_translations cache first to see if we've just changed the 
        # attribute and not saved yet.
        fallbacks.each do |fallback|
          result = stash.read(fallback, attr_name) || begin
            translation = translations.detect {|tr| tr.locale == fallback }
            translation && translation.send(attr_name)
          end
          if result
            locale = fallback
            break
          end
        end
        result && AttributeTranslation.new(result, :locale => locale, :requested_locale => requested_locale)
      end
    end
  end
end
