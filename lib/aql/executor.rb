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
          value = context.split_block.call(item)
          items << (value.kind_of?(Array) ? value : [value])
        end
      elsif context.find_by_block.size > 0
        context.find_by_block.each do |k, v|
          v.call(attributes[k], document).each do |item|
            value = context.split_block.call(item)
            items << (value.kind_of?(Array) ? value : [value])
          end
        end
      else
        while item = context.item_block.call(document)
          items << context.split_block.call(item)
        end
      end

      items = filter(items, attributes)
      items = colum_filter(items, @ast['SELECT']['targetList'])
    end

    def filter(items, attributes)
      attributes.each do |k, v|
        if k.kind_of?(Fixnum)
          items = items.find_all do |item|
            item[k-1] == v
          end
        end
      end

      items
    end

    def colum_filter(items, target_list)
      items.map do |item|
        result = []

        target_list.each do |target|
          val = expr_value(target['RESTARGET']['val'])

          case val
          when {"A_STAR"=>{}}
            result = item
          when Fixnum
            result << item[val-1]
          end
        end

        result
      end
    end

    def walk(aexpr, attributes)
      if aexpr['AEXPR']
        k = expr_value(aexpr['AEXPR']['lexpr'])
        v = expr_value(aexpr['AEXPR']['rexpr'])
        attributes[k] = v
      elsif aexpr['AEXPR AND']
        walk(aexpr['AEXPR AND']['lexpr'], attributes)
        walk(aexpr['AEXPR AND']['rexpr'], attributes)
      elsif aexpr['AEXPR OR']
        raise 'OR clauses are not supported yet'
      end
    end

    def expr_value(expr)
      if expr['COLUMNREF']
        expr['COLUMNREF']['fields'][0]
      elsif expr['A_CONST']
        expr['A_CONST']['val']
      end
    end

    def parser
      @parser ||= PgQuery
    end
  end
end
