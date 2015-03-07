require "spec_helper"
require "mystique"



scope Mystique do
  scope "::present" do
    Abc = Class.new
    AbcPresenter = Class.new(Mystique::Presenter)
    CbaPresenter = Class.new(Mystique::Presenter)

    spec "infers presenter class" do
      @presenter = Mystique.present(Abc.new)
      @presenter.is_a? AbcPresenter
    end

    spec "allows to pass a presenter class" do
      @presenter = Mystique.present(Abc.new, with: CbaPresenter)
      @presenter.is_a? CbaPresenter
    end

    spec "allows to pass a symbol for and infer the presenter from it" do
      @presenter = Mystique.present(Abc.new, with: :cba)
      @presenter.is_a? CbaPresenter
    end

    spec "allows to pass a string for and infer the presenter from it" do
      @presenter = Mystique.present(Abc.new, with: "cba")
      @presenter.is_a? CbaPresenter
    end

    spec "allows to pass a context" do
      @ctx = Object.new
      @presenter = Mystique.present(Abc.new, context: @ctx)
      @presenter.context == @ctx
    end
  end

  scope "contexts" do
    Contexts = Class.new

    Contexts::Ctx1 = :ctx1
    Contexts::Ctx2 = :ctx2

    class ContextsPresenter < Mystique::Presenter
      context Contexts::Ctx1

      def gimme_the_ctx
        context
      end
    end

    spec "allows to set a context at the class level" do
      @presenter = Mystique.present(Contexts.new)
      @presenter.context == Contexts::Ctx1
    end

    spec "allows to override the class level context" do
      @presenter = Mystique.present(Contexts.new, context: Contexts::Ctx2)
      @presenter.context == Contexts::Ctx2
    end

    spec "uses the class level context by default" do
      @presenter = Mystique.present(Contexts.new)
      @presenter.gimme_the_ctx == Contexts::Ctx1
    end

    spec "uses the new context if set" do
      @presenter = Mystique.present(Contexts.new, context: Contexts::Ctx2)
      @presenter.gimme_the_ctx == Contexts::Ctx2
    end
  end
end
