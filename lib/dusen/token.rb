# encoding: utf-8

module Dusen
  class Token

    attr_reader :field, :value, :exclude

    def initialize(options)
      @value = options.fetch(:value)
      @exclude = options.fetch(:exclude)
      @field = options.fetch(:field).to_s
    end

    def to_s
      value
    end

    def text?
      field == 'text'
    end

    def exclude?
      exclude
    end

  end
end
