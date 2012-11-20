module Dusen
  class Atom

    attr_reader :field, :value

    def initialize(*args)
      if args.length == 2
        @field, @value = args
      else
        @field = 'text'
        @value = args.first
      end
      @field = @field.to_s
    end

    def to_s
      value
    end

  end
end
