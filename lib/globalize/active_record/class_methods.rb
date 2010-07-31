module Globalize
  module ActiveRecord
    module ClassMethods
      delegate :available_locales, :set_translations_table_name, :to => :translation_class

      def with_locale(locale, &block)
        previous_locale, self.locale = self.locale, locale
        result = yield
        self.locale = previous_locale
        result
      end

      def with_locales(*locales)
        scoped & translation_class.with_locales(*locales)
      end

      def with_translations(*locales)
        locales = available_locales if locales.empty?
        includes(:translations).with_locales(locales).with_required_attributes
      end

      def with_required_attributes
        required_attributes.inject(scoped) do |scope, name|
          scope.where("#{translated_column_name(name)} IS NOT NULL")
        end
      end

      def with_translated_attribute(name, value, locales = nil)
        locales ||= Globalize.fallbacks(I18n.locale)
        with_translations.where(
          translated_column_name(name)    => value,
          translated_column_name(:locale) => locales.map(&:to_s)
        )
      end

      def required_attributes
        # TODO
        # @required_attributes ||= reflect_on_all_validations.select do |validation|
        #   validation.macro == :validates_presence_of && translated_attribute_names.include?(validation.name)
        # end.map(&:name)
        []
      end

      def translation_class
        klass = const_get(:Translation) rescue const_set(:Translation, Class.new(Translation))
        if klass.table_name == 'translations'
          klass.set_table_name(translation_options[:table_name])
          klass.belongs_to name.underscore.gsub('/', '_')
        end
        klass
      end

      def translations_table_name
        translation_class.table_name
      end

      def translated_column_name(name)
        "#{translation_class.table_name}.#{name}"
      end

      def respond_to?(method, *args, &block)
        method.to_s =~ /^find_by_(\w+)$/ && translated_attribute_names.include?($1.to_sym) || super
      end

      def method_missing(method, *args)
        if method.to_s =~ /^find_(first_|)by_(\w+)$/ && translated_attribute_names.include?($2.to_sym)
          result = with_translated_attribute($2, args.first)
          $1 == 'first_' ? result.first : result
        else
          super
        end
      end

      protected

        def translated_attr_accessor(name)
          define_method :"#{name}=", lambda { |value|
            globalize.write(self.class.locale || I18n.locale, name, value)
            self[name] = value
          }
          define_method name, lambda { |*args|
            globalize.fetch(args.first || self.class.locale || I18n.locale, name)
          }
          alias_method :"#{name}_before_type_cast", name
        end
    end
  end
end