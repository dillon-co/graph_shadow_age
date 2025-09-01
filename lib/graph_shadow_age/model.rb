# frozen_string_literal: true

module GraphShadowAGE
  module Model
    extend ActiveSupport::Concern

    included do
      class_attribute :_graph_properties, instance_writer: false, default: [:id, :created_at, :updated_at]

      after_commit :_graphshadow_upsert, on: [:create, :update]
      after_commit :_graphshadow_delete, on: :destroy
    end

    class_methods do
      def graph_properties(*cols)
        self._graph_properties = cols.map(&:to_sym) if cols.any?
        self._graph_properties
      end
    end

    private

    def _graphshadow_upsert
      GraphShadowAGE::Backfill.upsert_record(self.class, self.id)
    end

    def _graphshadow_delete
      klass = self.class
      label = GraphShadowAGE::Schema.label_for(klass)
      uid   = GraphShadowAGE::Schema.uid_for(klass, self.id)
      GraphShadowAGE.adapter.delete_node!(label, uid)
    end
  end
end
