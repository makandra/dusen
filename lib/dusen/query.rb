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
      texts = tokens.select(&:text?).collect(&:value)
      field_tokens = tokens.reject(&:text?)
      condensed_tokens = field_tokens
      condensed_tokens << Token.new(texts) if texts.present?
      self.class.new(condensed_tokens)
    end

  end
end
