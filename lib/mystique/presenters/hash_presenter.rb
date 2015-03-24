class HashPresenter < Mystique::Presenter
  def each
    super do |k, v|
      yield(Mystique.present(k), Mystique.present(v))
    end
  end
end
