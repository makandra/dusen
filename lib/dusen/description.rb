# encoding: utf-8

# This is the DSL to describe a Syntax.
module Dusen
  class Description

    attr_reader :syntax

    def initialize(syntax)
      @syntax = syntax
    end

    def search_by(field, &scoper)
      @syntax.learn_field(field, &scoper)
    end

    def self.parse_syntax(syntax, &dsl)
      description = new(syntax)
      description.instance_eval(&dsl)
      description.syntax
    end

  end
end
