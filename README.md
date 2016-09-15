# This gem is no longer maintained!

If you were using Dusen for its query parsing and LIKE queries, we recommend to migrate to [Minidusen](https://github.com/makandra/minidusen), which extracts those parts from Dusen. Minidusen is compatible with MySQL, PostgreSQL and modern versions of Rails.

If you are looking for a full text indexing solution, we recommend to use PostgreSQL with [pg_search](https://github.com/Casecommons/pg_search).

------

Dusen [![Build Status](https://secure.travis-ci.org/makandra/dusen.png?branch=master)](https://travis-ci.org/makandra/dusen)
======

Comprehensive search solution for ActiveRecord and MySQL
--------------------------------------------------------

Dusen lets you search ActiveRecord model when all you have is MySQL (no Solr, Sphinx, etc.). Here's what Dusen does for you:

1. It takes a text query in Google-like search syntax e.g. `some words "a phrase" filetype:pdf -excluded -"excluded  phrase" filetype:-txt`)
2. It parses the query into individual tokens.
3. It lets you define simple mappers that convert a token to an ActiveRecord scope chain. Mappers can match tokens using ActiveRecord's `where` or perform full text searches with either [LIKE queries](#processing-full-text-search-queries-with-like-queries) or [FULLTEXT indexes](#processing-full-text-queries-with-fulltext-indexes) (see [performance analysis](https://makandracards.com/makandra/12813-performance-analysis-of-mysql-s-fulltext-indexes-and-like-queries-for-full-text-search)).
4. It gives your model a method `Model.search('some query')` that performs all of the above and returns an ActiveRecord scope chain.


Processing full text search queries with LIKE queries
-----------------------------------------------------

This describes how to define a search syntax that processes queries
of words and phrases, e.g. `coworking fooville "market ave"`.

Under the hood the search will be performed using [LIKE queries](http://dev.mysql.com/doc/refman/5.0/en/string-comparison-functions.html#operator_like), which are [fast enough](https://makandracards.com/makandra/12813-performance-analysis-of-mysql-s-fulltext-indexes-and-like-queries-for-full-text-search) for medium sized data sets. Once your data outgrows LIKE queries, Dusen lets you [migrate to FULLTEXT indexes](#processing-full-text-queries-with-fulltext-indexes), which perform better but come at some added complexity.


### Setup and usage

Our example will be a simple address book:

    class Contact < ActiveRecord::Base
      validates_presence_of :name, :street, :city, :email
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

### What where_like does under the hood

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

You can also use `where_like` to find all the records *not* matching some phrases, using the `:negate` option:

    Contact.where_like({ :name => 'foo' }, { :negate => true })

Processing queries for qualified fields
---------------------------------------

Google supports queries like `filetype:pdf` that filters records by some criteria without performing a full text search. Dusen gives you a simple way to support such search syntax.

### Setup and usage

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


Note that you can combine text tokens and field tokens:

     > Contact.search('fooville email:foo@bar.com')
    => Contact.where_like(columns => 'fooville').where(:email => 'foo@bar.com')
    
### Caveat

If you search for a phrase containing a colon (e.g. `deploy:rollback`), Dusen
will mistake the first part as a – nonexistent – qualifier and return an empty
set.

To prevent that, prefix your query with the default qualifier `text`:

    text:deploy:rollback


Processing full text queries with FULLTEXT indexes
---------------------------------------------------

### When do I need this?

As your number of records grows larger, you might outgrow a full text implementation that uses LIKE (see [performance analysis](https://makandracards.com/makandra/12813-performance-analysis-of-mysql-s-fulltext-indexes-and-like-queries-for-full-text-search)). For this case Dusen ships with an alternative full text search solution using MySQL FULLTEXT indexes that scale much better.

### Understanding the MyISAM limitation

Using this feature comes at some added complexity so you should first check if search performance is actually a problem for you. If all you have is a few thousand records with a few dozen words each, changes are your views render many times longer than a LIKE query takes to finish. Always measure before optimizing.

Currently stable MySQL versions only allow FULLTEXT indexes on MyISAM tables (this will change in MySQL 5.6). You don't however want to migrate your models to MyISAM tables because of their many limitations (poor crash recovery, no transactions, etc.).

To work around this, Dusen uses a separate MyISAM table `search_texts` to index your searchable text. Each row in your model's table will be shadowed by a corresponding row in `search_texts`. Dusen will automatically create, update and destroy these shadow rows as your model records change.


### Setup and usage

First we need to create the `search_texts` table. Since we're on Rails, we will do this using a migration. So enter `rails generate migration CreateSearchText` and use the following code as the migration's content:

    class CreateSearchText < ActiveRecord::Migration
    
      def self.up
        create_table :search_texts, :options => 'ENGINE=MyISAM' do |t|
          t.integer :source_id
          t.string :source_type
          t.boolean :stale
          t.text :words
        end
        add_index :search_texts, [:source_type, :source_id] # for updates
        add_index :search_texts, [:source_type, :stale] # for refreshs
        execute 'CREATE FULLTEXT INDEX fulltext_index_words ON search_texts (words)'
      end
    
      def self.down
        drop_table :search_texts
      end
    
    end

Since we're using some MySQL-specific options we also need to change the format of your `db/schema.rb` from Ruby to SQL (you will get a `db/schema.sql` instead). You can configure this in your `application.rb` (`environment.rb` in Rails 2):

    config.active_record.schema_format = :sql


We now need to your model which text to index. We do this using the `search_text` macro and returning the searchable text:

    class Contact < ActiveRecord::Base

      search_syntax

      search_text do
        [name, street, city, email]
      end

    end

You can return any object or array of objects. Dusen will stringify the return value and index those words. Note that indexed words do not need to be fields of your model:

    search_text do
      [email, city, author.screen_name, ('client' if client?)
    end

You're done! You can now search `Contact` using the same API you used with [LIKE queries](#processing-full-text-search-queries-with-like-queries):

    Contact.search('coworking fooville "market ave"')

Note that you didn't need to teach your model how to process text queries by defining a mapper with `search_by :text { ... }`. The `search_text` macro defines this mapper for you.

Also note that if you migrated an existing table to FULLTEXT search, you need to [build the index the first time](#building-the-index-for-existing-records).


### Building the index for existing records

If you migrated an existing table to FULLTEXT search, you must build the index for all existing records:

    Model.all.each(&:index_search_text)

You only need to do this once. Dusen will automatically index all further changes to your records.


### Indexing changes in associated records

Dusen lets you index words from associated models. When you do this you need to reindex the indexed model whenever an associated record changes, or else the indexed text will be out of date.

As an example we will associate `Contact` with an `Organization` and make it searchable by the name of her `Organization`:

    class Contact < ActiveRecord::Base
      
      belongs_to :organization
      
      search_syntax

      search_text do
        [name, email, organization && organization.name]
      end

    end

To make sure contacts will reindex when the organization changes its name, use the `part_of_search_text_for` macro:

    class Organization < ActiveRecord::Base

      has_many :contacts
 
      part_of_search_text_for do
        contacts
      end

    end

All records returned by `part_of_search_text_for` will be reindexed when the organization is changed or destroyed.


### Obtaining the currently indexed words

To access a string of words that is indexed for a record, call `#search_text`:

    contact = Contact.create!(:email => 'foo@bar.com', :city => 'Foohausen')
    context.search_text # => "foo@bar.com Foohausen"

This can be practical if you want to index a record under the same words as its association:

    class Contact < ActiveRecord::Base

      belongs_to :organization

      search_syntax

      search_text do
        [name, email, organization.search_text]
      end

    end


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


Supported Rails versions
------------------------

Dusen is tested against Rails 3.0 and Rails 3.2. There is also a branch rails-2-3, which is tested against Rails 2.3.


Installation
------------

In your `Gemfile` say:

    gem 'dusen'

Now run `bundle install` and restart your server.


Development
-----------

- Test applications for various Rails versions lives in `spec`.
- You need to create a MySQL database and put credentials into `spec/shared/app_root/config/database.yml`.
- You can bundle all test applications by saying `bundle exec rake all:bundle`
- You can run specs from the project root by saying `bundle exec rake all:spec`.

If you would like to contribute:

- Fork the repository.
- Push your changes **with passing specs**.
- Send me a pull request.

I'm very eager to keep this gem lightweight and on topic. If you're unsure whether a change would make it into the gem, [talk to me beforehand](mailto:henning.koch@makandra.de).


Credits
-------

Henning Koch from [makandra](http://makandra.com/)
