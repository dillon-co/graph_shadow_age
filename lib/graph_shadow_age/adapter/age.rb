# frozen_string_literal: true

module GraphShadowAGE
  module Adapter
    class AGE
      def initialize(config)
        @config = config
      end

      def graph_name
        @config.graph_name
      end

      # Naive literal quoting for PoC
      def q(v)
        case v
        when nil then "NULL"
        when Numeric then v.to_s
        when TrueClass, FalseClass then v ? "true" : "false"
        else ActiveRecord::Base.connection.quote(v)
        end
      end

      def exec(sql)
        ActiveRecord::Base.connection.execute(sql)
      end

      def install!
        exec("CREATE EXTENSION IF NOT EXISTS age;")
        exec("LOAD 'age';") rescue nil
        exec("SELECT * FROM create_graph('#{graph_name}');") rescue nil
        # unique constraint per label will be created lazily during backfill (pooled by label)
      end

      def cypher(query, params = {})
        # No param passing in PoC (AGE supports params via cypher_params, omitted here)
        sql = "SELECT * FROM cypher('#{graph_name}', $$ #{query} $$) as (v agtype);"
        exec(sql)
      end

      def ensure_uid_constraint!(label)
        cypher("CREATE CONSTRAINT ON (n:#{label}) ASSERT n.uid IS UNIQUE;") rescue nil
      end

      # Upsert a node using MERGE on uid, then SET properties
      def upsert_node!(label, uid, props = {})
        ensure_uid_constraint!(label)
        set_body = props.map { |k, v| "#{k}: #{q(v)}" }.join(", ")
        cypher(<<~CYPHER)
          MERGE (n:#{label} {uid: #{q(uid)}})
          SET n += { #{set_body} }
          RETURN n;
        CYPHER
      end

      def delete_node!(label, uid)
        cypher(<<~CYPHER)
          MATCH (n:#{label} {uid: #{q(uid)}}) DETACH DELETE n;
        CYPHER
      end

      # Ensure both endpoints exist, then MERGE edge of given type (dir: from -> to)
      def upsert_edge!(from_label, from_uid, type, to_label, to_uid, props = {})
        set_body = props.any? ? "SET r += { " + props.map { |k, v| "#{k}: #{q(v)}" }.join(", ") + " }" : ""
        cypher(<<~CYPHER)
          MERGE (a:#{from_label} {uid: #{q(from_uid)}})
          MERGE (b:#{to_label} {uid: #{q(to_uid)}})
          MERGE (a)-[r:#{type}]->(b)
          #{set_body}
          RETURN r;
        CYPHER
      end

      def delete_edges_from!(from_label, from_uid)
        cypher(<<~CYPHER)
          MATCH (a:#{from_label} {uid: #{q(from_uid)}})-[r]->()
          DELETE r;
        CYPHER
      end
    end
  end
end
