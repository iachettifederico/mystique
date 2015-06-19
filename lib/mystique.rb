require "mystique/version"

require "callable"
require "string_plus"

require "mystique/undefined"
require "mystique/presenter"

module Mystique
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

  def present_collection(collection, context: nil, &block)
    return to_enum(:present_collection, collection, context: context, &block) unless block_given?

    collection.each do |element|
      block.call present(element, context: context)
    end
  end
end
