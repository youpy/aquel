require 'sql-parser'

module Aql
  class Executor
    attr_reader :context

    def initialize
      @contexts = {}
    end

    def define(name, &block)
      @contexts[name] = Context.new(block)

      self
    end

    def execute(sql)
      @ast = parser.scan_str(sql)
      type = @ast.query_expression.table_expression.from_clause.tables.first.name

      context = @contexts[type]
      context.execute!

      items = []
      document = context.document_block.call(attributes)

      if context.items_block
        context.items_block.call(document).each do |item|
          items << context.split_block.call(item)
        end
      elsif context.find_by_block.size > 0
        context.find_by_block.each do |k, v|
          v.call(attributes[k], document).each do |item|
            items << context.split_block.call(item)
          end
        end
      else
        while item = context.item_block.call(document)
          items << context.split_block.call(item)
        end
      end

      items.map do |item|
        result = []

        if @ast.query_expression.list.kind_of?(SQLParser::Statement::All)
          result = item
        else
          @ast.query_expression.list.columns.each do |select|
            case select.value
            when Fixnum
              result << item[select.value.to_i-1]
            end
          end
        end

        result
      end
    end

    def attributes
      result = {}
      search_condition = @ast.query_expression.table_expression.where_clause.search_condition

      if search_condition.kind_of?(SQLParser::Statement::And)
        result[search_condition.left.left.name] = search_condition.left.right.value
        result[search_condition.right.left.name] = search_condition.right.right.value
      else
        result[search_condition.left.name] = search_condition.right.value
      end

      result
    end

    def parser
      @parser ||= SQLParser::Parser.new
    end
  end
end
