module Dusen
  class Description

    attr_reader :syntax

    def initialize
      @syntax = Syntax.new
    end

    def search_by(field, &scoper)
      @syntax.learn_field(field, &scoper)
    end

    def self.read_syntax(&dsl)
      description = new
      description.instance_eval(&dsl)
      description.syntax
    end

  end
end
