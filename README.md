# GraphqlGenerator

## Installation

If your project included the GraphQL generator inside the `lib` folder, start by getting rid of the `lib/generators` directory.

Add this line to your application's Gemfile:

```ruby
gem 'graphql_generator', github: 'moku-io/graphql_generator'
```

And then execute:

    $ bundle

## Usage

Generate type files for a given model `ModelName`:

    $ rails g type_helper ModelName 
    
This command comes with the following options:
- `--no-type`: skip type generation
- `--no-policy`: skip policy generation
- `--no-input`: skip input generation
- `--no-mutations`: skip mutations generation
- `--no-dependencies`: skip dependencies generation

## Development

After checking out the repo, run `bin/setup` to install dependencies. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/[USERNAME]/graphql_generator.


## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).

