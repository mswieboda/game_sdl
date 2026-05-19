require "yaml"

module GSDL
  struct DialogChoice
    include YAML::Serializable

    getter text : String
    getter next_id : String
    getter actions : Array(String)?
    getter conditions : Array(String)?
  end

  struct DialogNode
    include YAML::Serializable

    getter text : String
    getter choices : Array(DialogChoice)?
  end

  module DialogManager
    @@dialogs = Hash(String, DialogNode).new
    @@mutex = Mutex.new

    # Sets up the DialogManager.
    def self.setup
    end

    def self.load(path_key : String)
      @@mutex.synchronize do
        data = {% if flag?(:release) %}
          GSDL::AssetManager.load_raw_data(path_key)
        {% else %}
          full_path = GSDL::AssetManager.asset_path + path_key
          File.open(full_path) do |file|
            slice = Bytes.new(file.size.to_i)
            file.read_fully(slice)
            slice
          end
        {% end %}
        
        @@dialogs = Hash(String, DialogNode).from_yaml(String.new(data))
      end
    end

    def self.get_node(id : String) : DialogNode?
      @@mutex.synchronize do
        @@dialogs[id]?
      end
    end

    def self.clear_all : Nil
      @@mutex.synchronize do
        @@dialogs.clear
      end
    end
  end
end
