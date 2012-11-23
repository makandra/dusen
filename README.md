Dusen - Maps Google-like queries to ActiveRecord scopes
=======================================================


Dusen gives your ActiveRecord models a DSL to process Google-like queries like:

    some words
    "a phrase of words"
    filetype:pdf
    a mix of words "and phrases" and qualified:fields

Dusen tokenizes these queries for you and feeds them through simple mappers that
convert a token to an ActiveRecord scope chain.
This process is packaged in a class method `.search`:

    Contact.search('makandra software "Ruby on Rails" city:augsburg')


Installation
------------

In your `Gemfile` say:

    gem 'dusen'

Now run `bundle install` and restart your server.



Processing text queries
-----------------------

This describes how to define a search syntax that processes queries
of words and phrases:

    coworking fooville "market ave"


Our example will be a simple address book:

    class Contact < ActiveRecord::Base

      validates_presence_of :name, :street, :city, :name

    end


We will now teach `Contact` to process a text query like this:

    class Contact < ActiveRecord::Base

      ...

      search_syntax do

        search_by :text do |scope, phrase|
          columns = [:name, :street, :city, :email]
          scope.where_like(columns => phrase)
        end

      end

    end


Note how you will only ever need to deal with a single token (word or phrase) and return a scope that matches the token.
Dusen will take care how these scopes will be chained together.

If we now call `Contact.search('coworking fooville "market ave"')`
the block supplied to `search_by` is called once per token:

1. `|Contact, 'coworking'|`
2. `|Contact.where_like(columns => 'coworking'), 'fooville'|`
3. `|Contact.where_like(columns => 'coworking').where_like(columns => 'fooville'), 'market ave'|`


The resulting scope chain is your `Contact` model filtered by
the given query:

     > Contact.search('coworking fooville "market ave"')
    => Contact.where_like(columns => 'coworking').where_like(columns => 'fooville').where_like(columns => 'market ave')


Note that `where_like` is an utility method that comes with the Dusen gem.
It takes one or more column names and a phrase and generates an SQL fragment
like this:

    contacts.name LIKE "%coworking%" OR contacts.street LIKE "%coworking%" OR contacts.email LIKE "%coworking%" OR contacts.email LIKE "%coworking%"


Processing queries for qualified fields
---------------------------------------

Let's give `Contact` a way to explictely search for a contact's email address, without
going through a full text search. We do this by adding additional `search_by` instructions
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



Programmatic access without DSL
-------------------------------

You can use Dusen's functionality without using the ActiveRecord DSL or the search scope. Here are some method calls to get you started:

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
- Push your changes **with specs**.
- Send me a pull request.

I'm very eager to keep this gem leightweight and on topic. If you're unsure whether a change would make it into the gem, [talk to me beforehand](mailto:henning.koch@makandra.de).


Credits
-------

Henning Koch from [makandra](http://makandra.com/)
