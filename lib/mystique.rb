require "mystique/version"

require "callable"
require "string_plus"

require "mystique/null_context"


module Mystique
  class Presenter
    def initialize(object, context)
      @__object__ = object
      @__context__ = context || self.class.context || NullContext
    end

    def self.present(object, context=nil)
      self.new(object, context).tap do |presenter|
        yield presenter if block_given?
      end
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
      value = target.send(method, *args, &block)
      result = if __formats__.keys.include?(value)
                 __formats__[value]
               elsif __regex_formats__.any? { |regex, _| value =~ regex}
                 __regex_formats__.select { |regex, _| value =~ regex}.first.last
               elsif __class_formats__.any? { |klass, _| value.is_a?(klass)}
                 __class_formats__.select { |klass, _| value.is_a?(klass)}.first.last
               else
                 value
               end
      Callable(result).call(value, context)
    end

    def self.context(ctx=Undefined)
      @__context__ = ctx unless ctx == Undefined
      @__context__
    end

    def self.format(matcher, value=nil, &block)
      __formats__[matcher] = block_given? ? block : value
    end

    def self.format_multiple(*matchers, &block)
      matchers.each do |matcher|
        format(matcher, &block)
      end
    end

    def __formats__
      self.class.__formats__
    end

    def self.__formats__
      @__formats__ ||= {
                        nil => "-----",
                       }
    end

    def __regex_formats__
      self.class.__regex_formats__
    end

    def self.__regex_formats__
      @__regex_formats__ ||= __formats__.select {|k, v| k.is_a?(Regexp)}
    end

    def __class_formats__
      self.class.__class_formats__
    end

    def self.__class_formats__
      @__class_formats__ ||= __formats__.select {|k, v| k.is_a?(Class)}
    end
  end

  class Undefined; end

  module_function

  def present(object, with: nil, context: nil, &block)
    presenter_class = case with
                      when nil
                        begin
                          "#{object.class}Presenter".constantize
                        rescue NameError => e
                          return object
                        end
                      when Symbol, String
                        "#{with}Presenter".constantize
                      else
                        with
                      end
    presenter_class.present(object, context, &block)
  end
end
