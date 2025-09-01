# graph_shadow_age (PoC)

A tiny proof-of-concept gem that derives a graph schema from your Rails models and mirrors your relational data into
an Apache AGE graph inside the same Postgres database.

## The Motivation & Goal

[Pepur](www.pepur.xyz) is an LLM assisted event platform that leverages A.I. for coordinating all different parts of events (events, attendees, sponsors, venues, staff) 
working with SQL and vector databases with LLM querys is extremely limited and forces the developer to manually add specific functions for searching connections between nodes. 
We need a better solution for LLM understanding, but rather than maintain a new database, why not just auto convert your existing sql to graph on the fly? 

Though SQL is still usseful and necessary, adding the ability for an LLM to search a knowledgegraph of your sql database unlocks a lot of potential.

### But why not just use python?
STFU. Rails is better. Fight me.

> **Status**: PoC. Not production safe; interpolation is simplistic and aiming for learn-by-doing.

## Quick start

1. Add to your Gemfile (path or git for now):

```ruby
gem "graph_shadow_age", path: "/path/to/graph_shadow_age"
```

2. Configure (e.g., in `config/initializers/graph_shadow_age.rb`):

```ruby
GraphShadowAGE.configure do |c|
  c.graph_name = "app_graph"
  c.models = [User, Event, Ticket, Sponsor, Staff]
  c.logger = Rails.logger
end
```

3. Install AGE graph & constraints:

```
bin/rails graph_shadow_age:install
```

4. Backfill nodes/edges:

```
bin/rails graph_shadow_age:backfill
```

5. Enable callbacks (optional, PoC):

```ruby
# In each model you want mirrored:
class Event < ApplicationRecord
  include GraphShadowAGE::Model
  graph_properties :id, :name, :starts_at, :city
  # associations as normal
end
```

6. Run a Cypher query:

```ruby
GraphShadowAGE.cypher(<<~CYPHER)
  MATCH (e:Event)<-[:ATTENDED]-(u:User)
  RETURN e.name, count(DISTINCT u) AS attendees
  ORDER BY attendees DESC LIMIT 10
CYPHER
```

## What it does

- Creates an AGE graph (`create_graph` if missing)
- For each configured model, creates nodes with label == model name and a unique `uid`
- For each `belongs_to` and `has_and_belongs_to_many`/`has_many :through`, creates directed edges

## Caveats

- Uses naive string interpolation in MERGE queries — **do not** expose to untrusted input.
- Update handling is simplistic: re-upserts whole node and rebuilds edges for that source row.
- Only supports AGE for now.
