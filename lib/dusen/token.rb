# encoding: utf-8

module Dusen
  class Token

    attr_reader :field, :value, :negative

    def initialize(field, value, negative)
      @value = value
      @negative = negative
      @field = field.to_s
    end

    def to_s
      value
    end

    def text?
      field == 'text'
    end

    def negative?
      negative
    end

  end
end
