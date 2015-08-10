require "spec_helper"
require "mystique"
require "mystique/presenters/hash_presenter"

scope HashPresenter do
  Hash1 = Class.new
  Hash2 = Class.new

  class Hash1Presenter < Mystique::Presenter
  end
  class Hash2Presenter < Mystique::Presenter
  end

  spec "it presents keys and values" do
    @h1 = Hash1
    @h2 = Hash2
    @hash = {
             :a  => :b,
             :c  => @h1,
             @h2 => :d
            }

    @expected = {
                 :a  => :b,
                 :c  => @h1,
                 @h2 => :d
                }
    Mystique.present(@hash).zip(@expected).all? { |res, expected|
      res.first == expected.first
    }
  end
end
