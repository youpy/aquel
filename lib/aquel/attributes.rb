module Aquel
  class Attributes < Hash
    def equal_values
      self.class[
        *(self.find_all do |k, v|
          v[:name] == '='
        end.map do |k, v|
          [k, v[:value]]
        end.flatten)
      ]
    end
  end
end
