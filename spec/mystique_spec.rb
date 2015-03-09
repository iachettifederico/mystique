require "spec_helper"
require "mystique"



scope Mystique do
  scope "::present" do
    Abc = Class.new
    AbcPresenter = Class.new(Mystique::Presenter)
    CbaPresenter = Class.new(Mystique::Presenter)

    spec "it returns the target object if there's no presenter available" do
      @target = :a_target
      @presenter = Mystique.present(@target)
      @presenter == @target
    end
    
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

    spec "it passes the presenter to a block, if the block is given" do
      @ctx = Object.new
      @presenter = nil
      Mystique.present(Object.new, with: AbcPresenter) do |presenter|
        @presenter = presenter
      end
        
      @presenter.is_a? AbcPresenter
      
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

  scope "retreiving data" do
    Retrieve = Struct.new(:a, :b)

    class RetrieveContext
      def decorate(attr)
        ">>>>> #{attr} <<<<<"
      end
    end

    class RetrievePresenter < Mystique::Presenter
      context RetrieveContext.new

      def b
        "FROM PRESENTER: #{target.b}"
      end

      def e
        "E"
      end

      def f
        context.decorate(a)
      end
    end

    spec "it retrieves from the decorated object if the method is not found on the presenter" do
      @presenter = Mystique.present(Retrieve.new("A", "B"))
      @presenter.a == "A"
    end

    spec "it retrieves from the presenter if the method is available" do
      @presenter = Mystique.present(Retrieve.new("A", "B"))
      @presenter.e == "E"
    end

    spec "it retrieves an overriden method from the presenter" do
      @presenter = Mystique.present(Retrieve.new("A", "B"))
      @presenter.b == "FROM PRESENTER: B"
    end

    spec "it allows to use the context" do
      @presenter = Mystique.present(Retrieve.new("A", "B"))
      @presenter.f == ">>>>> A <<<<<"
    end
  end

  scope ".format" do
    class WebCtx
      def link_to(a, b)
        "<a href='#{b}'>#{a}</a>"
      end

      def number_to_currency(num, sym: "$")
        "%s %0.2f" % [sym, num]
      end
    end

    class FormatPresenter < Mystique::Presenter
      context WebCtx.new

      format nil, "N/A"

      format "value" do |value|
        value.upcase
      end

      format Integer, "I'm a number!"

      format /\w+@\w+\.com/ do |email, context|
        context.link_to(email, "mailto:#{email}")
      end

      format_multiple Date, Time do |value|
        value.to_date.strftime("%-d %b %Y")
      end

      format Float do |value, ctx|
        ctx.number_to_currency(value)
      end
    end

    spec "allows to format methods that return a specific value" do
      @item = OpenStruct.new(a: nil)
      @presenter = Mystique.present(@item, with: FormatPresenter)
      @presenter.a == "N/A"
    end

    spec "allows to format methods that return a value of a specific class" do
      @item = OpenStruct.new(n: 5)
      @presenter = Mystique.present(@item, with: FormatPresenter)
      @presenter.n == "I'm a number!"
    end

    spec "allows to format methods that return a value that matches a regex" do
      @item = OpenStruct.new(email: "fede@example.com")
      @presenter = Mystique.present(@item, with: FormatPresenter)
      @presenter.email == "<a href='mailto:fede@example.com'>fede@example.com</a>"
    end

    spec "allows to pass a block" do
      @item = OpenStruct.new(val: "value")
      @presenter = Mystique.present(@item, with: FormatPresenter)
      @presenter.val == "VALUE"
    end

    spec "allows to pass the context to the block" do
      @item = OpenStruct.new(num: 5.5)
      @presenter = Mystique.present(@item, with: FormatPresenter)
      @presenter.num == "$ 5.50"
    end

    spec "allows multiple matchers (Date)" do
      @item = OpenStruct.new(bdate: Date.new(1981, 6, 12))
      @presenter = Mystique.present(@item, with: FormatPresenter)
      @presenter.bdate == "12 Jun 1981"
    end

    spec "allows multiple matchers (Time)" do
      @item = OpenStruct.new(bdate: Time.new(1981, 6, 12, 0, 0, 0))
      @presenter = Mystique.present(@item, with: FormatPresenter)
      @presenter.bdate == "12 Jun 1981"
    end

    scope "order of formats" do
      class FormatOrderPresenter < Mystique::Presenter
        format String,  "class"
        format "hello", "literal"
        format /bye/,   "regex"
      end

      spec "matches literal first" do
        @obj = OpenStruct.new(value: "hello")
        @presenter = Mystique.present(@obj, with: FormatOrderPresenter)
        @presenter.value == "literal"
      end

      spec "matches regex second first" do
        @obj = OpenStruct.new(value: "bye")
        @presenter = Mystique.present(@obj, with: FormatOrderPresenter)
        @presenter.value == "regex"
      end

      spec "matches class last second first" do
        @obj = OpenStruct.new(value: "some other string")
        @presenter = Mystique.present(@obj, with: FormatOrderPresenter)
        @presenter.value == "class"
      end
    end
  end
end
