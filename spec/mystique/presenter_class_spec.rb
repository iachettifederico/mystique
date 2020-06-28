require "spec_helper"
require "mystique/presenter_class"
require "mystique/presenter"

describe Mystique::PresenterClass do
  MyClass = Class.new
  MyClassPresenter = Class.new(Mystique::Presenter)

  it "returns a presenter class and a class name" do
    presenter_class = Mystique::PresenterClass.new(::MyClass.new, nil)

    expect(presenter_class.to_class).to eql(MyClassPresenter)
    expect(presenter_class.class_name).to eql("MyClassPresenter")
  end

  it "can ignore the with parameter" do
    presenter_class = Mystique::PresenterClass.new(::MyClass.new)

    expect(presenter_class.to_class).to eql(MyClassPresenter)
    expect(presenter_class.class_name).to eql("MyClassPresenter")
  end

  it "can choose the presenter to use" do
    presenter_class = Mystique::PresenterClass.new(nil, MyClassPresenter)

    expect(presenter_class.to_class).to eql(MyClassPresenter)
    expect(presenter_class.class_name).to eql("MyClassPresenter")
  end

  describe "class name" do
    it "can receive a regular objecw" do
      presenter_class = Mystique::PresenterClass.new(double(class: "Obj"))

      expect(presenter_class.class_name).to eql("ObjPresenter")
    end

    it "can receive a string" do
      presenter_class = Mystique::PresenterClass.new("test")

      expect(presenter_class.class_name).to eql("TestPresenter")
    end

    it "can receive a symbol" do
      presenter_class = Mystique::PresenterClass.new(:test)

      expect(presenter_class.class_name).to eql("TestPresenter")
    end

    it "can receive a multi-word symbol" do
      presenter_class = Mystique::PresenterClass.new(:my_test_class)

      expect(presenter_class.class_name).to eql("MyTestClassPresenter")
    end

    it "can receive an array" do
      presenter_class = Mystique::PresenterClass.new([double(class: "Obj")])

      expect(presenter_class.class_name).to eql("ObjPresenter")
    end

    it "can receive an array with a symbol" do
      presenter_class = Mystique::PresenterClass.new([:my_sym])

      expect(presenter_class.class_name).to eql("MySymPresenter")
    end

    it "can use a symbol as a namespace" do
      presenter_class = Mystique::PresenterClass.new([:my_namespace, double(class: "MyClass")])

      expect(presenter_class.class_name).to eql("MyNamespace::MyClassPresenter")
    end

    it "can define a complex presenter" do
      presenter_class = Mystique::PresenterClass.new([:ns1, :my_namespace, :another_thing, double(class: "MyClass")])

      expect(presenter_class.class_name).to eql("Ns1::MyNamespace::AnotherThing::MyClassPresenter")
    end
  end
end
