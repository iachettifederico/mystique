require "mystique/version"

require "callable"

require "mystique/undefined"
require "mystique/presenter"

module Mystique
  def self.present(object, with: nil, context: nil, namespace: nil, &block)
    begin
      presenter_class = presenter_class_for(object, with, namespace: namespace)
      presenter_class.for(object, context, &block)
    rescue NameError
      return object
    end
  end

  def self.present_collection(collection, context: nil, with: nil, namespace: nil, &block)
    options = { context: context, with: with, namespace: namespace }

    return to_enum(:present_collection, collection, **options , &block) unless block_given?

    collection.each do |element|
      case block.arity
      when 2
        block.call( present(element, **options), element )
      else
        block.call( present(element, **options) )
      end
    end
  end

  private

  def self.presenter_class_for(object, with, namespace: )
    return with if with

    presenter_name = [
      namespace,
      "#{object.class}Presenter"
    ].join('::')

    Object.send(:const_get, presenter_name)
  end
end
