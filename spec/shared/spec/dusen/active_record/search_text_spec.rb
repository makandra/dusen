require 'spec_helper'

describe Dusen::ActiveRecord::SearchText do

  describe '.match' do

    it 'should find records for the given list of words' do
      match = User::WithFulltext.create!(:name => 'Abraham', :city => 'Fooville')
      no_match = User::WithFulltext.create!(:name => 'Elizabeth', :city => 'Fooville')
      matches = Dusen::ActiveRecord::SearchText.match(User::WithFulltext, ['Abraham', 'Fooville'])
      matches.all.should == [match]
    end

    it 'should find records by only giving the prefix of a word' do
      match = User::WithFulltext.create!(:name => 'Abraham')
      no_match = User::WithFulltext.create!(:name => 'Elizabeth')
      matches = Dusen::ActiveRecord::SearchText.match(User::WithFulltext, ['Abra'])
      matches.all.should == [match]
    end

  end

  describe '.synchronize_model' do

    it 'should refresh stale index records' do
      user = User::WithFulltext.create!(:name => 'Abraham')
      user.search_text_record.should be_stale
      Dusen::ActiveRecord::SearchText.synchronize_model(User::WithFulltext)
      user.search_text_record(true).should_not be_stale
    end

    it 'should remove index records that no longer map to a model record' do
      user = User::WithFulltext.create!
      Dusen::ActiveRecord::SearchText.count.should == 1
      User::WithFulltext.delete_all
      Dusen::ActiveRecord::SearchText.count.should == 1
      Dusen::ActiveRecord::SearchText.synchronize_model(User::WithFulltext)
      Dusen::ActiveRecord::SearchText.count.should be_zero
    end

    it 'should not remove non-orphaned index records when called with a scope that excludes their source (bugfix)' do
      user1 = User::WithFulltext.create!
      user2 = User::WithFulltext.create!
      Dusen::ActiveRecord::SearchText.count.should == 2
      scope = Dusen::Util.append_scope_conditions(User::WithFulltext, :id => [user2.id])
      Dusen::ActiveRecord::SearchText.synchronize_model(scope)
      Dusen::ActiveRecord::SearchText.count.should == 2
    end

  end

end

