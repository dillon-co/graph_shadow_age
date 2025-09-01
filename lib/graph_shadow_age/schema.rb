# frozen_string_literal: true

module GraphShadowAGE
  module Schema
    module_function

    def label_for(klass)
      klass.name
    end

    def uid_for(klass, id)
      "#{klass.name}:#{id}"
    end

    # returns an array of belongs_to reflections
    def belongs_to_assocs(klass)
      klass.reflections.values.select { |r| r.macro == :belongs_to }
    end

    def through_assocs(klass)
      klass.reflections.values.select { |r| r.macro == :has_many && r.options[:through] }
    end

    def habtm_assocs(klass)
      klass.reflections.values.select { |r| r.macro == :has_and_belongs_to_many }
    end
  end
end
