require "mystique/version"

require "callable"

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

  def present_collection(collection, context: nil, with: nil, &block)
    return to_enum(:present_collection, collection, context: context, with: with, &block) unless block_given?

    collection.each do |element|
      case block.arity
      when 2
        block.call( present(element, context: context, with: with), element )
      else
        block.call(present(element, context: context, with: with))
      end
    end
  end

  def presenter_class_for(object, with)
    with || Object.send(:const_get, "#{object.class}Presenter")
  end
  private :presenter_class_for
end
