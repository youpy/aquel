require "aquel/context"
require "aquel/executor"
require "aquel/version"

module Aquel
  def define(name, &block)
    Executor.new.define(name, &block)
  end

  module_function :define
end
