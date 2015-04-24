module Aquel
  class Context
    attr_reader :document_block, :item_block, :items_block, :split_block, :find_by_block

    def initialize(block)
      @block = block
      @find_by_block = {}
      @header = false
    end

    def execute(attributes)
      instance_eval(&@block)

      items = []
      document = document_block.call(attributes.equal_values)

      if items_block
        items_block.call(document).each do |item|
          value = split_block.call(item)
          items << (value.kind_of?(Array) ? value : [value])
        end
      elsif find_by_block.size > 0
        find_by_block.each do |k, v|
          v.call(attributes.equal_values[k], document).each do |item|
            value = split_block.call(item)
            items << (value.kind_of?(Array) ? value : [value])
          end
        end
      else
        while item = item_block.call(document)
          items << split_block.call(item)
        end
      end

      if @header
        header = items.shift.map(&:downcase)
      else
        header = (1..(items.first.size)).to_a
      end

      items.map do |itm|
        item = {}
        itm.each_with_index { |v, i| item[header[i]] = v }
        item
      end
    ensure
      if document.respond_to?(:close)
        document.close
      end
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

    def has_header
      @header = true
    end
  end
end
