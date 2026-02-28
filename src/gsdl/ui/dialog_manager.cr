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

  class DialogManager
    @@instance : DialogManager? = nil

    @dialogs : Hash(String, DialogNode) = {} of String => DialogNode

    def self.instance : DialogManager
      @@instance ||= new
    end

    def self.load(path_key : String)
      instance.load(path_key)
    end

    def self.get_node(id : String) : DialogNode?
      instance.get_node(id)
    end

    def load(path_key : String)
      {% if flag?(:release) %}
        data = GSDL::AssetManager.load_raw_data(path_key)
        @dialogs = Hash(String, DialogNode).from_yaml(String.new(data))
      {% else %}
        full_path = GSDL::AssetManager.asset_path + path_key
        File.open(full_path) do |file|
          @dialogs = Hash(String, DialogNode).from_yaml(file)
        end
      {% end %}
    end

    def get_node(id : String) : DialogNode?
      @dialogs[id]?
    end
  end
end
