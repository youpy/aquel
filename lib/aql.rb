require "aql/context"
require "aql/executor"
require "aql/version"

module Aql
  def define(name, &block)
    Executor.new.define(name, &block)
  end

  module_function :define
end
