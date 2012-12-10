# encoding: utf-8

module User
  class WithoutFulltext < ActiveRecord::Base

    self.table_name = 'users_without_fulltext'

    search_syntax do

      search_by :text do |scope, text|
        scope.where_like([:name, :email, :city] => text)
      end

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

    end

  end

end
