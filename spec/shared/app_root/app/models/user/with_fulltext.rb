# encoding: utf-8

module User
  class WithFulltext < ActiveRecord::Base

    self.table_name = 'users_with_fulltext'

    search_syntax do

      search_by :city do |scope, city|
        scope.scoped(:conditions => { :city => city })
      end

      search_by :email do |scope, email|
        scope.scoped(:conditions => { :email => email })
      end

    end

    search_syntax do # multiple search_syntax directives are allowed

      search_by :role do |scope, role|
        scope.scoped(:conditions => { :role => role })
      end

      search_by :name_and_city_regex do |scope, regex|
        #Example for regexes that need to be and'ed together by syntax#build_exclude_scope
        first = scope.where("users_with_fulltext.name REGEXP ?", regex)
        second = scope.where("users_with_fulltext.city REGEXP ?", regex)
        first.merge(second)
      end
    end

    search_text do
      [name, email, city]
    end

  end

end

