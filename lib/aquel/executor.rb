require 'pg_query'

module Aquel
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
      ast = parser.parse(sql).parsetree.first
      type = ast['SELECT']['fromClause'][0]['RANGEVAR']['relname']

      items = []
      attributes = Attributes.new

      walk(ast['SELECT']['whereClause'], attributes)
      context = @contexts[type]
      items = context.execute(attributes)
      items = filter(items, attributes)
      items = colum_filter(items, ast['SELECT']['targetList'])
    end

    def filter(items, attributes)
      attributes.each do |k, v|
        case k
        when Fixnum
          items = items.find_all do |item|
            v.operate(item[k])
          end
        when String
          items = items.find_all do |item|
            if item[k]
              v.operate(item[k])
            else
              true
            end
          end
        end
      end

      items
    end

    def colum_filter(items, target_list)
      items.map do |item|
        result = {}

        target_list.each do |target|
          val = expr_value(target['RESTARGET']['val'])

          case val
          when {"A_STAR"=>{}}
            result = item
          when Fixnum
            result[val] = item[val]
          when String
            result[val] = item[val]
          end
        end

        result
      end
    end

    def walk(node, attributes)
      if aexpr = node['AEXPR']
        k = expr_value(aexpr['lexpr'])
        v = expr_value(aexpr['rexpr'])
        attributes[k] = Attribute.new(:value => v, :name => aexpr['name'][0])
      elsif aexpr = node['AEXPR AND']
        walk(aexpr['lexpr'], attributes)
        walk(aexpr['rexpr'], attributes)
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
