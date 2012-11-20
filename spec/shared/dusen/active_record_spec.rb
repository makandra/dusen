require 'spec_helper'

describe Dusen::ActiveRecord do

  describe '.search' do

    it 'should find records by given words' do
      match = User.create!(:name => 'foo')
      no_match = User.create!(:name => 'bar')
      User.search('foo').to_a.should == [match]
    end

    it 'should AND multiple words' do
      match = User.create!(:name => 'foo bar')
      no_match = User.create!(:name => 'foo')
      User.search('foo bar').to_a.should == [match]
    end

    it 'should find records by phrases' do
      match = User.create!(:name => 'foo bar baz')
      no_match = User.create!(:name => 'foo baz bar')
      User.search('"foo bar"').to_a.should == [match]
    end

    it 'should find records by qualified fields' do
      match = User.create!(:name => 'foo@bar.com', :email => 'foo@bar.com')
      no_match = User.create!(:name => 'foo@bar.com', :email => 'bam@baz.com')
      User.search('email:foo@bar.com').to_a.should == [match]
    end

    it 'should allow phrases as values for qualified field queries' do
      match = User.create!(:name => 'Foo Bar', :city => 'Foo Bar')
      no_match = User.create!(:name => 'Foo Bar', :city => 'Bar Foo')
      User.search('city:"Foo Bar"').to_a.should == [match]
    end

    it 'should allow to mix multiple types of atoms in a single query' do
      match = User.create!(:name => 'Foo', :city => 'Foohausen')
      no_match = User.create!(:name => 'Foo', :city => 'Barhausen')
      User.search('Foo city:Foohausen').to_a.should == [match]
    end

  end

end
