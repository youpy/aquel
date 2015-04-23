# aquel

**a**(nything) **que**(ry) **l**(anguage)

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'aquel'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install aquel

## Usage

```ruby
aquel = Aquel.define 'tsv' do
  document do |attributes|
    open(attributes['path'])
  end

  item do |document|
    document.gets
  end

  split do |item|
    item.chomp.split(/\t/)
  end
end

items = aquel.execute("select 1,3 from tsv where path = '/path/to/file.tsv' and 1 = 'foo'")
```

```ruby
require 'open-uri'

aquel = Aquel.define 'html' do
  document do |attributes|
    Nokogiri::HTML(open(attributes['url']))
  end

  find_by('css') do |css, document|
    document.css(css)
  end

  split do |item|
    item.text
  end
end

items = aquel.execute("select * from html where url = 'http://example.com/foo' and css = 'div.bar'")
```

## Contributing

1. Fork it ( https://github.com/youpy/aquel/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request
