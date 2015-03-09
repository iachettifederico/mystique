module Mystique
  module NullContext
    def method_missing(*)
      self
    end
  end
end
