module Dusen
  class Query

    include Enumerable

    def initialize
      @atoms = []
    end

    def <<(atom)
      @atoms << atom
    end

    def to_s
      collect(&:to_s).join(" + ")
    end

    def each(&block)
      @atoms.each(&block)
    end

  end
end
