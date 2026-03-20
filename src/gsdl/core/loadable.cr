module GSDL
  module Loadable
    def load_assets
      # fonts
      default_font_path_key = load_default_font

      unless default_font_path_key.empty?
        FontManager.load_default(path: default_font_path_key)
      end

      font_data = load_fonts
      font_data.each do |key, path_key, size|
        FontManager.load(key: key, path_key: path_key, size: size)
      end

      # textures
      texture_load_data = load_textures
      texture_load_data.each do |key, path_key|
        TextureManager.load(key: key, path_key: path_key)
      end

      # audio
      audio_load_data = load_audio
      audio_load_data.each do |key, path_key|
        AudioManager.load(key: key, path_key: path_key)
      end

      # tile maps
      tile_map_load_data = load_tile_maps
      tile_map_load_data.each do |key, path_key|
        TileMapManager.load(key: key, path_key: path_key)
      end

      # dialogs
      dialog_load_data = load_dialogs
      dialog_load_data.each do |path_key|
        DialogManager.load(path_key: path_key)
      end
    end

    def manifest : Array(Loader::AssetTask)
      tasks = [] of Loader::AssetTask

      load_fonts.each do |key, path_key, size|
        tasks << Loader::AssetTask.new(:Font, key, path_key, size)
      end

      load_textures.each do |key, path_key|
        tasks << Loader::AssetTask.new(:Texture, key, path_key)
      end

      load_audio.each do |key, path_key|
        tasks << Loader::AssetTask.new(:Audio, key, path_key)
      end

      load_tile_maps.each do |key, path_key|
        tasks << Loader::AssetTask.new(:TileMap, key, path_key)
      end

      load_dialogs.each do |path_key|
        tasks << Loader::AssetTask.new(:Dialog, "", path_key)
      end

      tasks
    end

    def load_default_font : String
      ""
    end

    def load_fonts : Array(Tuple(String, String, Float32))
      [] of Tuple(String, String, Float32)
    end

    def load_textures : Array(Tuple(String, String))
      [] of Tuple(String, String)
    end

    def load_audio : Array(Tuple(String, String))
      [] of Tuple(String, String)
    end

    def load_tile_maps : Array(Tuple(String, String))
      [] of Tuple(String, String)
    end

    def load_dialogs : Array(String)
      [] of String
    end
  end
end
