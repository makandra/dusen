Dusen [![Build Status](https://secure.travis-ci.org/makandra/dusen.png?branch=master)](https://travis-ci.org/makandra/dusen)
======

Comprehensive search solution for ActiveRecord and MySQL
--------------------------------------------------------

Dusen lets you search ActiveRecord model when all you have is MySQL (no Solr, Sphinx, etc.). Here's what Dusen does for you:

1. It takes a text query in Google-like syntax (e.g. `some words "a phrase" filetype:pdf`)
2. It parses the query into individual tokens.
3. It lets you define simple mappers that convert a token to an ActiveRecord scope chain. Mappers can match tokens using ActiveRecord's `where` or perform full text searches with either [LIKE queries](#processing-full-text-search-queries-with-like-queries) or [FULLTEXT indexes](#processing-full-text-queries-with-fulltext-indexes) (see [performance analysis](https://makandracards.com/makandra/12813-performance-analysis-of-mysql-s-fulltext-indexes-and-like-queries-for-full-text-search)).
4. It gives your model a method `Model.search('some query')` that performs all of the above and returns an ActiveRecord scope chain.


Installation
------------

In your `Gemfile` say:

    gem 'dusen'

Now run `bundle install` and restart your server.



Processing full text search queries with LIKE queries
-----------------------------------------------------

This describes how to define a search syntax that processes queries
of words and phrases, e.g. `coworking fooville "market ave"`.


Under the hood the search will be performed using [LIKE queries](http://dev.mysql.com/doc/refman/5.0/en/string-comparison-functions.html#operator_like), which are [fast enough](https://makandracards.com/makandra/12813-performance-analysis-of-mysql-s-fulltext-indexes-and-like-queries-for-full-text-search) for medium sized data sets. Once your data outgrows LIKE queries, Dusen lets you [migrate to FULLTEXT indexes](#processing-full-text-queries-with-fulltext-indexes), which perform better but come at some added complexity.

Our example will be a simple address book:

    class Contact < ActiveRecord::Base
      validates_presence_of :name, :street, :city, :name
    end


In order to teach `Contact` how to process a text query, use the `search_syntax` and `search_by :text` macros:

    class Contact < ActiveRecord::Base

      ...

      search_syntax do

        search_by :text do |scope, phrases|
          columns = [:name, :street, :city, :email]
          scope.where_like(columns => phrases)
        end

      end

    end


Dusen will tokenize the query into individual phrases and call the `search_by :text` block with it. The block is expected to return a scope that filters by the given phrases.

If, for example, we call `Contact.search('coworking fooville "market ave"')`
the block supplied to `search_by :text` is called with the following arguments:

    |Contact, ['coworking', 'fooville', 'market ave']|


The resulting scope chain is your `Contact` model filtered by
the given query:

     > Contact.search('coworking fooville "market ave"')
    => Contact.where_like([:name, :street, :city, :email] => ['coworking', 'fooville', 'market ave'])


Note that `where_like` is an utility method that comes with the Dusen gem.
It takes one or more column names and one or more phrases and generates an SQL fragment
that looks roughly like the following:

    ( contacts.name LIKE "%coworking%"    OR 
      contacts.street LIKE "%coworking%"  OR 
      contacts.email LIKE "%coworking%"   OR 
      contacts.email LIKE "%coworking%" ) AND
    ( contacts.name LIKE "%fooville%"     OR 
      contacts.street LIKE "%fooville%"   OR 
      contacts.email LIKE "%fooville%"    OR 
      contacts.email LIKE "%fooville%" )  AND
    ( contacts.name LIKE "%market ave%"   OR 
      contacts.street LIKE "%market ave%" OR 
      contacts.email LIKE "%market ave%"  OR 
      contacts.email LIKE "%market ave%" )


Processing queries for qualified fields
---------------------------------------

We now want to process a qualified query like `email:foo@bar.com` to
explictily search for a contact's email address, without going through
a full text search.

We can learn this syntax by adding a `search_by :email` instruction
to our model:

    search_syntax do

      search_by :text do |scope, phrase|
        ...
      end

      search_by :email do |scope, email|
        scope.where(:email => email)
      end

    end


The result is this:

     > Contact.search('email:foo@bar.com')
    => Contact.where(:email => 'foo@bar.com')


Feel free to combine text tokens and field tokens:

     > Contact.search('fooville email:foo@bar.com')
    => Contact.where_like(columns => 'fooville').where(:email => 'foo@bar.com')


Processing full text queries with FULLTEXT indexes
---------------------------------------------------

TODO


Programmatic access without DSL
-------------------------------

You can use Dusen's functionality without using the ActiveRecord DSL or the `search` method.
**Please note that at this time we cannot yet commit to the API of these internal methods**. So don't get mad when stuff breaks after you update the gem.

Here are some method calls to get you started:

    Contact.search_syntax # => #<Dusen::Syntax>

    syntax = Dusen::Syntax.new
    syntax.learn_field :email do |scope, email|
      scope.where(:email => email)
    end

    query = Dusen::Parser.parse('fooville email:foo@bar.com') # => #<Dusen::Query>
    query.tokens # => [#<Dusen::Token field: 'text', value: 'fooville'>, #<Dusen::Token field: 'email', value: 'foo@bar.com'>]
    query.to_s # => "fooville + foo@bar.com"

    syntax.search(Contact, query) # => #<ActiveRecord::Relation>


Development
-----------

Test applications for various Rails versions lives in `spec`. You can run specs from the project root by saying:

    bundle exec rake all:spec

If you would like to contribute:

- Fork the repository.
- Push your changes **with passing specs**.
- Send me a pull request.

I'm very eager to keep this gem leightweight and on topic. If you're unsure whether a change would make it into the gem, [talk to me beforehand](mailto:henning.koch@makandra.de).


Credits
-------

Henning Koch from [makandra](http://makandra.com/)
