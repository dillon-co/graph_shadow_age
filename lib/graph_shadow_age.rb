# frozen_string_literal: true

require "active_record"
require "active_support"
require "active_support/core_ext/module/attribute_accessors"
require_relative "graph_shadow_age/version"
require_relative "graph_shadow_age/config"
require_relative "graph_shadow_age/adapter/age"
require_relative "graph_shadow_age/schema"
require_relative "graph_shadow_age/model"
require_relative "graph_shadow_age/backfill"
require_relative "graph_shadow_age/sync/callbacks"

module GraphShadowAGE
  mattr_accessor :config

  def self.configure
    self.config ||= Config.new
    yield(config)
  end

  def self.logger
    (config && config.logger) || Logger.new($stdout)
  end

  def self.adapter
    @adapter ||= Adapter::AGE.new(config)
  end

  def self.cypher(query, params = {})
    adapter.cypher(query, params)
  end
end
