# frozen_string_literal: true

Gem::Specification.new do |s|
  s.name        = "graph_shadow_age"
  s.version     = GraphShadowAGE::VERSION
  s.summary     = "Auto-build a graph 'shadow' in Apache AGE from your Rails models."
  s.description = "Proof-of-concept: infer nodes and edges from ActiveRecord associations and sync into Apache AGE."
  s.authors     = ["Dillon + ChatGPT"]
  s.email       = ["devnull@example.com"]
  s.files       = Dir["lib/**/*", "README.md", "LICENSE.txt"]
  s.homepage    = "https://example.com/graph_shadow_age"
  s.license     = "MIT"
  s.required_ruby_version = ">= 3.0"
  s.add_dependency "activerecord", ">= 6.1"
  s.add_dependency "activesupport", ">= 6.1"
  s.add_dependency "pg", ">= 1.4"
end
