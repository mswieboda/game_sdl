require "../src/game_sdl"

# Simple entity for testing
class TestEntity < GSDL::Entity
  property health : Int32 = 10

  def save_state : Hash(String, JSON::Any)
    state = super
    state["health"] = JSON::Any.new(health.to_i64)
    state
  end

  def load_state(state : Hash(String, JSON::Any))
    super
    @health = state["health"].as_i
  end
end

# 1. Setup Scene
scene = GSDL::Scene.new(:test_room)
entity = TestEntity.new
entity.x = 100
entity.y = 200
entity.health = 50
scene.add_child(entity)

# 2. Save Snapshot
snapshot = scene.save_snapshot
puts "Scene Snapshot: #{snapshot.to_json}"

# 3. Simulate Load
puts "Simulating entity load..."
entity2 = TestEntity.new
entity_state = snapshot["entities"].as_h["entity_0"].as_h
entity2.load_state(entity_state)

puts "Loaded Entity: x=#{entity2.x}, y=#{entity2.y}, health=#{entity2.health}"

if entity2.x == 100 && entity2.y == 200 && entity2.health == 50
  puts "SUCCESS: Scene snapshot and load working."
else
  puts "FAILURE: Data mismatch."
  exit 1
end
