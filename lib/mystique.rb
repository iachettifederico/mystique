require "mystique/version"

require "callable"
require "string_plus"

require "mystique/undefined"
require "mystique/presenter"

module Mystique
  module_function

  def present(object, with: nil, context: nil, &block)
    begin
      presenter_class = presenter_class_for(object, with)
      presenter_class.for(object, context, &block)
    rescue NameError
      return object
    end
  end

  def present_collection(collection, context: nil, &block)
    return to_enum(:present_collection, collection, context: context, &block) unless block_given?

    collection.each do |element|
      case block.arity
      when 2
        block.call( present(element, context: context), element )
      else
        block.call(present(element, context: context))
      end
    end
  end

  def presenter_class_for(object, with)
    if with.respond_to?(:for)
      with
    else
      StringPlus.constantize("#{with || object.class}Presenter")
    end
  end
  private :presenter_class_for
end
