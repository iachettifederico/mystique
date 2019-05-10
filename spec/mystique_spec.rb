require "spec_helper"
require "mystique"
require "time"
require "ostruct"

describe Mystique do
  describe "::present" do
    Abc = Struct.new(:str) do
      def inspect
        "Abc Class"
      end
    end

    AbcPresenter = Class.new(Mystique::Presenter)

    CbaPresenter = Class.new(Mystique::Presenter)

    it "it returns the target object if there's no presenter available" do
      target    = :a_target
      presenter = Mystique.present(target)

      expect(presenter).to eql(target)
    end

    it "infers presenter class" do
      presenter = Mystique.present(Abc.new)
      expect(presenter).to be_a(AbcPresenter)
    end

    it "allows to pass a presenter class" do
      presenter = Mystique.present(Abc.new, with: CbaPresenter)

      expect(presenter).to be_a(CbaPresenter)
    end

    it "allows to pass a context" do
      ctx = Object.new
      presenter = Mystique.present(Abc.new, context: ctx)

      expect(presenter.context).to eql(ctx)
    end

    it "it passes the presenter to a block, if the block is given" do
      Mystique.present(Object.new, with: AbcPresenter) do |presenter|
        expect(presenter).to be_a(AbcPresenter)
      end
    end

    it "#inspect" do
      presenter = Mystique.present(Abc.new, context: :my_context)

      expect(presenter.inspect).to eql("<AbcPresenter(Abc Class) context: :my_context>")
    end
  end

  describe "contexts" do
    it "null context" do
      presenter = Mystique.present(Object.new, with: Mystique::Presenter)

      expect(presenter.context).to eql(Mystique::NullContext)
    end

    it "allows to set a context at the class level" do
      presenter_class = Class.new(Mystique::Presenter) do
        context :my_context
      end
      presenter = Mystique.present(Object.new, with: presenter_class)

      expect(presenter.context).to eql(:my_context)
    end

    it "allows to override the class level context" do
      presenter_class = Class.new(Mystique::Presenter) do
        context :my_context
      end

      presenter = Mystique.present(Object.new,
                                   context: :my_new_context,
                                   with: presenter_class)

      expect(presenter.context).to eql(:my_new_context)
    end

    it "uses the class level context by default" do
      presenter_class = Class.new(Mystique::Presenter) do
        context :original_context

        def gimme_the_ctx
          context
        end
      end

      presenter = Mystique.present(Object.new, with: presenter_class)

      expect(presenter.gimme_the_ctx).to eql(:original_context)
    end
  end

  describe "retreiving data" do
    let(:item) { Struct.new(:a, :b).new("A", "B") }

    let(:context) { Class.new do
                      def decorate(attr)
                        ">>>>> #{attr} <<<<<"
                      end
                    end.new
    }

    let(:presenter_class) {
      Class.new(Mystique::Presenter) do |a|

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
    }

    let(:presenter) {
      Mystique.present(item, with: presenter_class, context: SomeContext.new)
    }

    it "it retrieves from the decorated object if the method is not found on the presenter" do
      presenter = Mystique.present(item, with: presenter_class)

      expect(presenter.a).to eql("A")
    end

    it "it retrieves from the presenter if the method is available" do
      presenter = Mystique.present(item, with: presenter_class)

      expect(presenter.e).to eql("E")
    end

    it "it retrieves an overriden method from the presenter" do
      presenter = Mystique.present(item, with: presenter_class)

      presenter.b == "FROM PRESENTER: B"
    end

    it "it allows to use the context" do
      presenter = Mystique.present(item, with: presenter_class, context: context)

      presenter.f == ">>>>> A <<<<<"
    end
  end

  describe ".format" do
    let(:web_context) {
      Class.new do
        def link_to(a, b)
          "<a href='#{b}'>#{a}</a>"
        end

        def number_to_currency(num, sym: "$")
          "%s %0.2f" % [sym, num]
        end
      end.new
    }

    it "allows to format methods that return a specific value" do
      presenter_class = Class.new(Mystique::Presenter) do
        format :a

        apply_format nil, 'N/A'
      end

      item      = OpenStruct.new(a: nil)
      presenter = Mystique.present(item, with: presenter_class)

      expect(presenter.a).to eql("N/A")
    end

    it "allows to format methods that return a value of a specific class" do
      presenter_class = Class.new(Mystique::Presenter) do
        format :number

        apply_format Integer, "I'm a number!"
      end

      item = OpenStruct.new(number: 5)
      presenter = Mystique.present(item, with: presenter_class)

      expect(presenter.number).to eql("I'm a number!")
    end

    it "allows to format methods that return a value that matches a regex" do
      presenter_class = Class.new(Mystique::Presenter) do
        format :email

        apply_format(/\w+@\w+\.com/) do |email, context|
          context.link_to(email, "mailto:#{email}")
        end
      end

      item = OpenStruct.new(email: "fede@example.com")
      presenter = Mystique.present(item, with: presenter_class, context: web_context)

      expect(presenter.email).to eql("<a href='mailto:fede@example.com'>fede@example.com</a>")
    end

    it "allows to pass a block" do
      presenter_class = Class.new(Mystique::Presenter) do
        format :val

        apply_format "value" do |value|
          value.upcase
        end
      end

      item = OpenStruct.new(val: "value")
      presenter = Mystique.present(item, with: presenter_class)

      expect(presenter.val).to eql("VALUE")
    end

    it "allows to pass the context to the block" do
      presenter_class = Class.new(Mystique::Presenter) do
        format :price

        apply_format Float do |value, ctx|
          ctx.number_to_currency(value)
        end
      end

      item = OpenStruct.new(price: 5.5)
      presenter = Mystique.present(item, with: presenter_class, context: web_context)

      expect(presenter.price).to eql("$ 5.50")
    end

    it "allows multiple matchers (Date)" do
      presenter_class = Class.new(Mystique::Presenter) do
        format :bdate

        format_multiple Date, Time do |value|
          value.to_date.strftime("%-d %b %Y")
        end
      end

      item = OpenStruct.new(bdate: Date.new(1981, 6, 12))
      presenter = Mystique.present(item, with: presenter_class)

      presenter.bdate == "12 Jun 1981"
    end

    it "allows multiple matchers (Time)" do
      presenter_class = Class.new(Mystique::Presenter) do
        format :bdate

        format_multiple Date, Time do |value|
          value.to_date.strftime("%-d %b %Y")
        end
      end

      item = OpenStruct.new(bdate: Time.new(1981, 6, 12, 0, 0, 0))
      presenter = Mystique.present(item, with: presenter_class)
      presenter.bdate == "12 Jun 1981"
    end

    describe "order of formats" do
      let(:presenter_class) {
        Class.new(Mystique::Presenter) do
          apply_format String,  "class"
          apply_format "hello", "literal"
          apply_format(/bye/, "regex")

          format :value
        end
      }

      it "matches literal first" do
        obj = OpenStruct.new(value: "hello")
        presenter = Mystique.present(obj, with: presenter_class)

        expect(presenter.value).to eql("literal")
      end

      it "matches regex second first" do
        obj = OpenStruct.new(value: "bye")
        presenter = Mystique.present(obj, with: presenter_class)

        expect(presenter.value).to eql("regex")
      end

      it "matches class last second first" do
        obj = OpenStruct.new(value: "some other string")
        presenter = Mystique.present(obj, with: presenter_class)

        expect(presenter.value).to eql("class")
      end
    end
  end

  describe "super" do
    it "it redirects to the target object" do
      target_class = Struct.new(:name)

      presenter_class = Class.new(Mystique::Presenter) do
        def name
          super.capitalize
        end
      end

      presenter = Mystique.present(target_class.new("Super"))
      expect(presenter.name).to eql("Super")
    end
  end

  describe "conversion methods" do
    let(:target) {
      Class.new do
        def inspect
          "Conversions Class"
        end

        def to_i
          42
        end

        def to_f
          42.5
        end
      end.new
    }

    let(:presenter_class) {
      Class.new(Mystique::Presenter) do
        context :my_context

        apply_format Integer, 100

        def to_f
          42.0
        end
      end
    }

    let(:presenter) { Mystique.present(target, with: presenter_class) }

    describe "String" do
      it "to_s" do
        /#<ConversionsPresenter:0x\h+>/ === presenter.to_s
      end

      it "to_i" do
        presenter.to_i == 42
      end

      it "to_f" do
        presenter.to_i == 42.0
      end

      it "to_whatever" do
        expect { presenter.to_whatever }.to raise_error(NoMethodError)
      end
    end
  end

  describe ":present_collection" do
    Element = Struct.new(:str)

    class ElementPresenter < Mystique::Presenter
      apply_format(String) { |v| v.upcase }

      format :str
    end


    let(:collection) {
      [
        Element.new("a"),
        Element.new("b"),
        Element.new("c"),
      ]
    }

    let(:presenter) { Mystique.present_collection(collection) }

    it "it returns a Enumerator" do
      expect(presenter).to be_a(Enumerator)
    end

    it "it returns a Enumerator that yields presenters" do
      expect(presenter.map(&:str)).to eql(%w[A B C])
    end

    it "it returns a Enumerator that yields presenters" do
      result = presenter.map { |presenter, element|
        [presenter.str, element.str]
      }

      expect(result).to eql([['A', 'a'], ['B', 'b'], ['C', 'c']])
    end

    it "it yields presenters" do
      presenters = []
      Mystique.present_collection(collection) do |el|
        presenters << el.str
      end

      expect(presenters).to eql(%w[A B C])
    end
  end

  describe "#format" do
    let(:target_class) { Struct.new(:value) }
    let(:presenter_class) {
      Class.new(Mystique::Presenter) do
        apply_format(String) { |v| v.upcase }

        def value
          format(target.value)
        end

        def donttouchme
          target.value
        end

        def to_s
          format(target.value)
        end
      end
    }

    it "returns raw value by default" do
      target = target_class.new("a string")
      presenter = Mystique.present(target, with: presenter_class)

      expect(presenter.donttouchme).to eql("a string")
    end

    it "formats a string" do
      target = target_class.new("a string")
      presenter = Mystique.present(target, with: presenter_class)

      expect(presenter.value).to eql("A STRING")
    end

    it "formats to_* methods" do
      target = target_class.new("#to_s works!")
      presenter = Mystique.present(target, with: presenter_class)

      expect(presenter.value).to eql("#TO_S WORKS!")
    end
  end

  describe "inheritance" do
    class BasePresenter < Mystique::Presenter
      apply_format nil, "N/A"
    end

    class ChildPresenter < BasePresenter
      format :attr
    end

    Child = Struct.new(:attr)

    it "it inherits formats" do
      presenter = Mystique.present(Child.new)

      expect(presenter.attr).to eql('N/A')
    end
  end

  describe "presenting and formatting" do
    Item = Struct.new(:attr)
    PresentedClass = Class.new
    class PresentedClassPresenter < Mystique::Presenter
    end

    it "it delegates to the presented object" do
      delegate_to_item_presenter = Class.new(Mystique::Presenter) do
        apply_format nil, "N/A"
      end

      presenter = delegate_to_item_presenter.for(Item.new(nil))

      expect(presenter.attr).to eql(nil)
    end

    it "it formats the attr method" do
      format_item_attr_presenter = Class.new(Mystique::Presenter) do
        apply_format nil, "N/A"
        format :attr
      end

      presenter = format_item_attr_presenter.for(Item.new(nil))

      expect(presenter.attr).to eql("N/A")
    end

    it "it presents the attr method" do
      present_item_attr_presenter = Class.new(Mystique::Presenter) do
        apply_format nil, "N/A"
        present :attr
      end

      presenter = present_item_attr_presenter.for(Item.new(PresentedClass.new))

      expect(presenter.attr).to be_a(PresentedClassPresenter)
    end

    it "it presents the attr method if it's formatted and presented" do
      present_item_attr_presenter = Class.new(Mystique::Presenter) do
        apply_format nil, "N/A"
        format :attr
        present :attr
      end

      presenter = present_item_attr_presenter.for(Item.new(PresentedClass.new))

      expect(presenter.attr).to be_a(PresentedClassPresenter)
    end

    it "it formats the attr method if it's formatted and presented" do
      present_item_attr_presenter = Class.new(Mystique::Presenter) do
        apply_format nil, "N/A"
        format :attr
        present :attr
      end

      presenter = present_item_attr_presenter.for(Item.new(nil))

      expect(presenter.attr).to eql('N/A')
    end

  end
end
