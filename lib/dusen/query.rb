module Dusen
  class Query

    include Enumerable

    def initialize
      @tokens = []
    end

    def <<(token)
      @tokens << token
    end

    def to_s
      collect(&:to_s).join(" + ")
    end

    def each(&block)
      @tokens.each(&block)
    end

  end
end
