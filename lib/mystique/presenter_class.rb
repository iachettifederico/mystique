module Mystique
  class PresenterClass
    def initialize(object, with=nil)
      @with   = with
      @object = object
    end

    def to_class
      with || Object.send(:const_get, class_name)
    end

    def class_name
      return with.to_s if with

      "#{base_class_name(object)}Presenter"
    end

    private

    attr_reader :with
    attr_reader :object

    def base_class_name(for_object)
      case for_object
      when Symbol, String
        for_object.to_s.split(/_/).map(&:capitalize).join
      when Array
        for_object.map { |current_object|
          base_class_name(current_object)
        }.join("::")
      else
        for_object.class.to_s
      end
    end
  end
end
