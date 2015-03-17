# encoding: utf-8

module Dusen
  class Query

    include Enumerable

    attr_reader :tokens

    def initialize(initial_tokens = [])
      @tokens = initial_tokens
    end

    def <<(token)
      tokens << token
    end

    def [](index)
      tokens[index]
    end

    #def +(tokens)
    #  tokens.each do |token|
    #    self << token
    #  end
    #end

    def to_s
      collect(&:to_s).join(" + ")
    end

    def each(&block)
      tokens.each(&block)
    end

    def condensed
      positive_texts = positive.select(&:text?).collect(&:value)
      negative_texts = negative.select(&:text?).collect(&:value)
      field_tokens = tokens.reject(&:text?)

      condensed_tokens = field_tokens
      condensed_tokens << Token.new('text', positive_texts, false) if positive_texts.present?
      condensed_tokens << Token.new('text', negative_texts, true) if negative_texts.present?
      self.class.new(condensed_tokens)
    end

    def positive
      tokens.reject(&:negative?)
    end

    def negative
      tokens.select(&:negative?)
    end

  end
end
