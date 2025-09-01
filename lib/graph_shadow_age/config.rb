# frozen_string_literal: true

module GraphShadowAGE
  class Config
    attr_accessor :graph_name, :models, :logger

    def initialize
      @graph_name = "app_graph"
      @models = []
      @logger = Logger.new($stdout)
    end
  end
end
