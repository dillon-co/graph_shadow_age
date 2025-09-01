# frozen_string_literal: true

module GraphShadowAGE
  module Backfill
    module_function

    def install!
      GraphShadowAGE.adapter.install!
    end

    def backfill!
      install!
      GraphShadowAGE.config.models.each do |klass|
        label = Schema.label_for(klass)
        GraphShadowAGE.adapter.ensure_uid_constraint!(label)
      end
      GraphShadowAGE.config.models.each do |klass|
        klass.find_each(batch_size: 1000) do |rec|
          upsert_record(klass, rec.id)
        end
      end
    end

    def upsert_record(klass, id)
      rec = klass.find_by(id: id)
      return unless rec

      label = Schema.label_for(klass)
      uid   = Schema.uid_for(klass, rec.id)
      props = node_props(rec)

      GraphShadowAGE.adapter.upsert_node!(label, uid, props)

      # rebuild outward edges owned by this row
      GraphShadowAGE.adapter.delete_edges_from!(label, uid)
      create_belongs_to_edges(rec, label, uid)
      create_through_edges(rec, label, uid)
      create_habtm_edges(rec, label, uid)
    end

    def node_props(rec)
      cols = if rec.class.respond_to?(:_graph_properties)
               rec.class._graph_properties
             else
               [:id, :created_at, :updated_at]
             end
      props = {}
      cols.each { |c| props[c] = rec.send(c) if rec.respond_to?(c) }
      props
    end

    def create_belongs_to_edges(rec, from_label, from_uid)
      Schema.belongs_to_assocs(rec.class).each do |ref|
        fk_val = rec.send(ref.foreign_key)
        next unless fk_val

        target_klass = ref.klass
        to_label = Schema.label_for(target_klass)
        to_uid   = Schema.uid_for(target_klass, fk_val)
        type     = ref.name.to_s.upcase # e.g., author -> AUTHOR
        GraphShadowAGE.adapter.upsert_edge!(from_label, from_uid, type, to_label, to_uid)
      end
    end

    def create_through_edges(rec, from_label, from_uid)
      Schema.through_assocs(rec.class).each do |ref|
        # Build edges to target through association
        targets = rec.send(ref.name)
        targets.find_each { |t|
          to_label = Schema.label_for(t.class)
          to_uid   = Schema.uid_for(t.class, t.id)
          type     = ref.name.to_s.singularize.upcase # attendees -> ATTENDEE (rough heuristic)
          GraphShadowAGE.adapter.upsert_edge!(from_label, from_uid, type, to_label, to_uid)
        } if targets.respond_to?(:find_each)
      end
    end

    def create_habtm_edges(rec, from_label, from_uid)
      Schema.habtm_assocs(rec.class).each do |ref|
        targets = rec.send(ref.name)
        targets.find_each { |t|
          to_label = Schema.label_for(t.class)
          to_uid   = Schema.uid_for(t.class, t.id)
          type     = ref.name.to_s.singularize.upcase
          GraphShadowAGE.adapter.upsert_edge!(from_label, from_uid, type, to_label, to_uid)
        } if targets.respond_to?(:find_each)
      end
    end
  end
end
