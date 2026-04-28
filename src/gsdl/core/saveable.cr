require "json"

module GSDL
  module Saveable
    abstract def save_state : Hash(String, JSON::Any)
    abstract def load_state(state : Hash(String, JSON::Any))
  end
end
