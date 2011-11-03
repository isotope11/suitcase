Suitcase
========

Suitcase is a Ruby library that utilizes the EAN (Expedia.com) API for locating available hotels, rental cars, and flights.

Installation
------------

Add the following line to your Gemfile:

`gem 'suitcase', :git => "http://github.com/thoughtfusion/suitcase.git"` then run `bundle install`. Or install the gem: `gem install suitcase`.

Next, include the module where you'll need it: `include Suitcase`.


Usage
-----
Find nearby hotels:

      Hotel::API_KEY = "your_api_key_here"
      Hotel.near('Boston, MA', 10) # Returns 10 closest hotels to Boston, MA
      Hotel.near('Metropoliton Museum of Art') # Returns 50 closest hotels to the MFA

Find available airline flights:

      Flight:API_KEY = "your_api_key_here"
      Flight.available('June 23 2012', :from => "BOS", :to => "LHR") # Return all flights flying from Boston to London (Heathrow) on June 23, 2012

Contributing
------------
Please submit any useful pull requests through GitHub. If you find any bugs, please report them! Thanks.
