require 'pg_query'

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
      @ast = parser.parse(sql).parsetree.first
      type = @ast['SELECT']['fromClause'][0]['RANGEVAR']['relname']

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

        @ast['SELECT']['targetList'].each do |target|
          val = target['RESTARGET']['val']

          case
          when val['COLUMNREF']
            result = item
          when val['A_CONST']
            result << item[val['A_CONST']['val']-1]
          end
        end

        result
      end
    end

    def attributes
      result = {}
      where = @ast['SELECT']['whereClause']

      if where['AEXPR AND']
        k = where['AEXPR AND']['lexpr']['AEXPR']['lexpr']['COLUMNREF']['fields'][0]
        v = where['AEXPR AND']['lexpr']['AEXPR']['rexpr']['COLUMNREF']['fields'][0]
        result[k] = v

        k = where['AEXPR AND']['rexpr']['AEXPR']['lexpr']['COLUMNREF']['fields'][0]
        v = where['AEXPR AND']['rexpr']['AEXPR']['rexpr']['COLUMNREF']['fields'][0]
        result[k] = v
      else
        k = where['AEXPR']['lexpr']['COLUMNREF']['fields'][0]
        v = where['AEXPR']['rexpr']['A_CONST']['val']

        result[k] = v
      end

      result
    end

    def parser
      @parser ||= PgQuery
    end
  end
end
