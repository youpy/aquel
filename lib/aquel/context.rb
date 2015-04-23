module Aquel
  class Context
    attr_reader :document_block, :item_block, :items_block, :split_block, :find_by_block

    def initialize(block)
      @block = block
      @find_by_block = {}
    end

    def execute!
      instance_eval(&@block)
    end

    def document(&block)
      @document_block = block
    end

    def item(&block)
      @item_block = block
    end

    def split(&block)
      @split_block = block
    end

    def items(&block)
      @items_block = block
    end

    def find_by(name, &block)
      @find_by_block[name] = block
    end
  end
end
