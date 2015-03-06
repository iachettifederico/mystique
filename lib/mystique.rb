require "mystique/version"
require "callable"
require "string_plus"

module Mystique
  class Presenter
    def initialize(object, context)
      @__object__ = object
      @__context__ = context
    end

    def self.present(object)
      new(object, context)
    end

    def h
      @__context__ || self.class.context
    end

    def target
      @__object__
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
      Callable(result).call(value)
    end

    def self.context(ctx=Undefined)
      @__context__ = ctx unless ctx == Undefined
      @__context__
    end

    def self.format(key, value)
      __formats__[key] = value
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

    class Undefined; end

    module_function

    def present(object, with: nil)
      from_module &&= "#{from_module.to_s.camelcase}::"
      presenter_class = case with
                        when nil
                          "#{object.class}Presenter".constantize
                        when Symbol, String
                          "#{presenter}Presenter".constantize
                        else
                          presenter
                        end
      presenter_class.present(object)
    end
  end
end
