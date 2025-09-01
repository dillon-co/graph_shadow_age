# frozen_string_literal: true

namespace :graph_shadow_age do
  desc "Install Apache AGE graph and basics"
  task install: :environment do
    GraphShadowAGE::Backfill.install!
    puts "[graph_shadow_age] Installed AGE graph '#{GraphShadowAGE.config.graph_name}'"
  end

  desc "Backfill nodes and edges into AGE"
  task backfill: :environment do
    GraphShadowAGE::Backfill.backfill!
    puts "[graph_shadow_age] Backfill complete"
  end
end
