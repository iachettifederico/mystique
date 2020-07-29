# Mystique

Mystique is a gem that implements the presenter pattern. It allows you to augment an object, by wrapping it and giving it access to the context in which you need to render it.

## How to present

Mystique ships with the `.present` method, which wraps the target object in a presenter and yield the presenter if a block is given, and returns it. If there default presenter is not available, the original object gets yielded/returned.

```ruby
Item = Struct.new(:name, :price)
class ItemPresenter < Mystique::Presenter
end

item_presenter = Mystique.present(Item.new("Rubik's Cube", 30.5))

item_presenter.class
# => ItemPresenter

item_presenter.name
# => "Rubik's Cube"
```

### Default presenter

The default presenter is inferred from the target object's class name. So, for the `Item` class, you'll get the `ItemPresenter` presenter.

If `ItemPresenter` is not defined, you'll get back your original item.

```ruby
Other = Class.new

other_presenter = Mystique.present(Other.new)

other_presenter.class
# => Other
```

### Context

The context is the object that, conveniently, provides the context in which the original object will be rendered.

Currently, the context defaults to a null context, which accepts any message sent and does nothing.

You can set the context in 3 ways:

#### Using the `.context` method when defining your presenter:

```ruby
module UrlHelpers
  def self.root_path
    "/"
  end
end

Web = Class.new

class WebPresenter < Mystique::Presenter
  context UrlHelpers

  def root
    h.root_path
  end
end

web_presenter = Mystique.present(Web.new)

web_presenter.root
# => "/"
```

This will set the `UrlHelpers` module as the context for any instance of `WebPresenter`

#### Passing it to the present method

```ruby
user_presenter = Mystique.present(some_web_instance, context: UrlHelpers)
```

Which will set `MyHelpers` as the context just for `user_presenter`

#### Both

You can pass the presenter using both methods.

In that case, the one set on the class declaration will be the default one for that class,
but if you pass a new context to a specific instance, it will use that one.

## Formatting

Mystique provides an `apply_format` method that allows you to define defaults for some response types.

In every case, `apply_format` will accept a value or a block to return, which will yield the found value and the context.

In order to apply that format to a method, you must specify which method by calling `format`. If you forget to do this, Mystique will just retrieve the value from the original object and return that.

### Specific values

This is a great way to return a default String when you get a nil back (but it's not limited to that).

```ruby
Item = Struct.new(:name, :price)
class ItemPresenter < Mystique::Presenter
  format :price

  apply_format nil, "N/A"
end

Mystique.present(Item.new("Headphones")) do |item_presenter|
  item_presenter.price            # => "N/A"
end
```

### Classes

You can pass a class name to the format method, and if the returned value is an instance of that class, it will return the specified value/block

```ruby
module Helpers
  def self.number_to_currency(number)
    "$ %0.2f" % number
  end
end

Item = Struct.new(:name, :price)

class ItemPresenter < Mystique::Presenter
  context Helpers
  apply_format Float do |value, context|
    context.number_to_currency(value)
  end

  format :price
end

item_presenter = Mystique.present(Item.new("Rubik's Cube", 5.3))

item_presenter.price
# => "$ 5.30"
```

### Regular Expressions

You can also pass a regular expression to which the return value will be matched

```ruby
module Helpers
  def self.link_to(text, url)
    "<a href='#{url}'> #{text} </a>"
  end
end

User = Struct.new(:name, :email)

class UserPresenter < Mystique::Presenter
  context Helpers

  format :email
  
  apply_format /\w+@\w+\.\w+/ do |email, context|
    context.link_to(email, "mailto://#{email}")
  end
end

user_presenter = Mystique.present(User.new("Federico", "me@myself.com"))

user_presenter.email
# => "<a href='mailto://me@myself.com'> me@myself.com </a>"
```

### `format_multiple`

You can also set multiple matchers by using the `.format_multiple` method:

```ruby
require "time"

User = Struct.new(:last_log_in)

class UserPresenter < Mystique::Presenter
  format :last_log_in
  
  format_multiple Date, Time do |value|
    value.to_date.strftime("%-d %b %Y")
  end
end

Mystique.present(User.new(Time.now)).last_log_in
# => "29 Jul 2020"

Mystique.present(User.new(Date.today)).last_log_in
# => "29 Jul 2020"
```

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'mystique'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install mystique


## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release` to create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

1. Fork it ( https://github.com/[my-github-username]/mystique/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request
