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
      include_texts = include.select(&:text?).collect(&:value)
      exclude_texts = exclude.select(&:text?).collect(&:value)
      field_tokens = tokens.reject(&:text?)

      condensed_tokens = field_tokens
      if include_texts.present?
        options = { :field => 'text', :value => include_texts, :exclude => false }
        condensed_tokens << Token.new(options)
      end
      if exclude_texts.present?
        options = { :field => 'text', :value => exclude_texts, :exclude => true }
        condensed_tokens << Token.new(options)
      end
      self.class.new(condensed_tokens)
    end

    def include
      self.class.new tokens.reject(&:exclude?)
    end

    def exclude
      self.class.new tokens.select(&:exclude?)
    end

  end
end
