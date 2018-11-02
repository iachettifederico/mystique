class HashPresenter < Mystique::Presenter
  def each
    super do |key, value|
      yield(Mystique.present(key), Mystique.present(value))
    end
  end
end
