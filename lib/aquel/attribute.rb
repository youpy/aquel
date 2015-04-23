module Aquel
  class Attribute
    attr_reader :name, :value

    def initialize(options)
      @name = options[:name]
      @value = options[:value]
    end

    def operate(target)
      case name
      when '='
        target == value
      when '<>'
        target != value
      else
        false
      end
    end
  end
end
