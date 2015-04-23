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
      attributes = {}

      walk(@ast['SELECT']['whereClause'], attributes)
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

    def walk(aexpr, attributes)
      if aexpr['AEXPR']
        k = aexpr['AEXPR']['lexpr']['COLUMNREF']['fields'][0]
        v = aexpr['AEXPR']['rexpr']['A_CONST']['val']
        attributes[k] = v
      elsif aexpr['AEXPR AND']
        walk(aexpr['AEXPR AND']['lexpr'], attributes)
        walk(aexpr['AEXPR AND']['rexpr'], attributes)
      elsif aexpr['AEXPR OR']
        raise 'OR clauses are not supported yet'
      end
    end

    def parser
      @parser ||= PgQuery
    end
  end
end
