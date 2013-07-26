# flay-js

TODO: Write a gem description

## Installation

Add this line to your application's Gemfile:

    gem 'flay-js'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install flay-js

## Usage

For general flay usage please see [flay docummentation](https://github.com/seattlerb/flay)

flay-js options:

    -e, --exclude PATH               Path to file with regular expressions for files to be skipped
                                       use '-e default' to skip jquery, jquery-ui, *.min.js and versioned file names
    -j, --javascript                 Run flay in javascript mode
                                       (in addition to *.js process javascript fragments in *.erb and *.haml

For exclusion file example check [default file](data/flay_js_exclude)



## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
