require "mystique/null_context"

module Mystique
  class Presenter
    FORMATS = {}

    def initialize(object, context)
      @__object__  = object
      @__context__ = context || self.class.context || NullContext
    end

    def self.for(object, context=nil)
      new(object, context).tap { |presenter|
        yield presenter if block_given?
      }
    end

    def context
      @__context__
    end
    alias :ctx :context
    alias :h :context

    def target
      @__object__
    end

    def inspect
      "<#{self.class}(#{target.inspect}) context: #{context.inspect}>"
    end

    private

    def method_missing(method, *args, &block)
      return target.send(method, *args, &block) if method.to_s.start_with?("to_")

      value = target.send(method, *args, &block)

      case
      when formatted_method?(method)
        format( value )
      when presented_method?(method)
        Mystique.present(value, context: context)
      when presented_collection?(method)
        Mystique.present_collection(value, context: context, &block)
      else
        value
      end
    end

    def formatted_method?(method)
      __formatted_methods__.include?(method)
    end

    def presented_method?(method)
      __presented_methods__.include?(method)
    end

    def presented_collection?(method)
      __presented_collections__.include?(method)
    end

    def format(value)
      result = if __formats__.keys.include?(value)
                 __formats__[value]
               elsif __regex_formats__.any? { |regex, _| value =~ regex}
                 __regex_formats__.select { |regex, _| value =~ regex}.first.last
               elsif __class_formats__.any? { |klass, _| value.is_a?(klass)}
                 __class_formats__.select { |klass, _| value.is_a?(klass)}.first.last
               else
                 value
               end
      Mystique.present(Callable(result).call(value, context))
    end

    def self.context(ctx=Undefined)
      @__context__ = ctx unless ctx == Undefined
      @__context__
    end

    def self.apply_format(matcher, value=nil, &block)
      __formats__[matcher] = block_given? ? block : value
    end

    def self.format(matcher)
      if matcher.is_a?(Symbol)
        __formatted_methods__ << matcher
      end
    end

    def self.present(matcher)
      if matcher.is_a?(Symbol)
        __presented_methods__ << matcher
      end
    end

    # TODO: Define this
    def self.present_collection(matcher)
      if matcher.is_a?(Symbol)
        __presented_collections__ << matcher
      end
    end

    def self.format_and_present(matcher)
      format_method(method)
      present_method(method)
    end

    def self.__presented_methods__
      @__presented_methods__ ||= []
    end

    def self.__presented_collections__
      @__presented_collections__ ||= []
    end

    def self.__formatted_methods__
      @__formatted_methods__ ||= []
    end

    def __presented_methods__
      self.class.__presented_methods__
    end

    def __presented_collections__
      self.class.__presented_collections__
    end

    def __formatted_methods__
      self.class.__formatted_methods__
    end

    def self.format_multiple(*matchers, &block)
      matchers.each do |matcher|
        apply_format(matcher, &block)
      end
    end

    def __formats__
      self.class.__formats__
    end

    def self.__formats__
      FORMATS
    end

    def __regex_formats__
      self.class.__regex_formats__
    end

    def self.__regex_formats__
      @__regex_formats__ ||= __formats__.select {|key, _| key.is_a?(Regexp)}
    end

    def __class_formats__
      self.class.__class_formats__
    end

    def self.__class_formats__
      @__class_formats__ ||= __formats__.select {|key, _| key.is_a?(Class)}
    end
  end
end
