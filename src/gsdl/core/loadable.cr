module GSDL
  module Loadable
    def load_assets
      # fonts
      default_font_path_key = load_default_font

      unless default_font_path_key.empty?
        FontManager.load_default(path: default_font_path_key)
      end

      load_fonts.each do |key, path_key, size|
        FontManager.load(key: key, path_key: path_key, size: size)
      end

      # font atlases
      load_font_atlases.each do |path_key, size, outline|
        FontAtlasManager.load(path_key: path_key, size: size, outline: outline)
      end

      # textures
      load_textures.each do |key, path_key|
        TextureManager.load(key: key, path_key: path_key)
      end

      # audio
      load_audio.each do |audio_tuple|
        case audio_tuple
        when Tuple(String, String)
          AudioManager.load(key: audio_tuple[0], path_key: audio_tuple[1])
        when Tuple(String, String, String)
          AudioManager.load(key: audio_tuple[0], path_key: audio_tuple[1], category: audio_tuple[2])
        end
      end

      # tile maps
      load_tile_maps.each do |key, path_key|
        TileMapManager.load(key: key, path_key: path_key)
      end

      # dialogs
      load_dialogs.each do |path_key|
        DialogManager.load(path_key: path_key)
      end
    end

    def manifest : Array(Loader::AssetTask)
      tasks = [] of Loader::AssetTask

      load_fonts.each do |key, path_key, size|
        tasks << Loader::AssetTask.new(AssetType::Font, key, path_key, size)
      end

      load_font_atlases.each do |path_key, size, outline|
        ext = File.extname(path)
        name = File.basename(path, ext)

        # NOTE: path_key isn't used later, but might as well include it, instead of ""
        tasks << Loader::AssetTask.new(AssetType::FontAtlas, key, path_key, size, outline)
      end

      load_textures.each do |key, path_key|
        tasks << Loader::AssetTask.new(AssetType::Texture, key, path_key)
      end

      load_audio.each do |audio_tuple|
        case audio_tuple
        when Tuple(String, String)
          tasks << Loader::AssetTask.new(AssetType::Audio, audio_tuple[0], audio_tuple[1])
        when Tuple(String, String, String)
          # Note: Loader::AssetTask would need an update for categories in async mode
          tasks << Loader::AssetTask.new(AssetType::Audio, audio_tuple[0], audio_tuple[1])
        end
      end

      load_tile_maps.each do |key, path_key|
        tasks << Loader::AssetTask.new(AssetType::TileMap, key, path_key)
      end

      load_dialogs.each do |path_key|
        tasks << Loader::AssetTask.new(AssetType::Dialog, "", path_key)
      end

      tasks
    end

    def load_default_font : String
      ""
    end

    def load_fonts : Array(Tuple(String, String, Float32))
      [] of Tuple(String, String, Float32)
    end

    # TODO: make a default_font_atlas with Tuple(String, Num, Int32)

    def load_font_atlases : Array(Tuple(String, Num, Int32))
      [] of Tuple(String, Num, Int32)
    end

    def load_textures : Array(Tuple(String, String))
      [] of Tuple(String, String)
    end

    def load_audio : Array(Tuple(String, String) | Tuple(String, String, String))
      [] of Tuple(String, String) | Tuple(String, String, String)
    end

    def load_tile_maps : Array(Tuple(String, String))
      [] of Tuple(String, String)
    end

    def load_dialogs : Array(String)
      [] of String
    end
  end
end
