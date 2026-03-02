require "../asset_manager"
require "../gfx/surface"

module GSDL
  class Loader
    class Progress
      @total_assets : Atomic(Int32) = Atomic(Int32).new(0)
      @loaded_assets : Atomic(Int32) = Atomic(Int32).new(0)

      def initialize
      end

      def set_total(count : Int32)
        @total_assets.set(count)
      end

      def increment_loaded
        @loaded_assets.add(1)
      end

      def percentage : Float32
        total = @total_assets.get
        return 100.0_f32 if total == 0
        (@loaded_assets.get.to_f32 / total) * 100.0_f32
      end

      def complete? : Bool
        total = @total_assets.get
        total > 0 && @loaded_assets.get >= total
      end

      def loaded_count : Int32
        @loaded_assets.get
      end

      def total_count : Int32
        @total_assets.get
      end
    end

    enum AssetType
      Texture
      Audio
      Font
      Dialog
      TileMap
    end

    record AssetTask, type : AssetType, key : String, path_key : String, size : Float32 = 0_f32

    @tasks = Array(AssetTask).new
    @progress = Progress.new
    
    @task_queue = Deque(AssetTask).new
    @task_mutex = Mutex.new
    
    @surface_queue = Deque(Tuple(String, Surface)).new
    @surface_mutex = Mutex.new
    
    @worker_threads = Array(Thread).new
    @max_workers = 4
    property max_assets_per_frame : Int32 = 10

    def initialize
    end

    def add_texture(key : String, path_key : String)
      @tasks << AssetTask.new(:Texture, key, path_key)
    end

    def add_audio(key : String, path_key : String)
      @tasks << AssetTask.new(:Audio, key, path_key)
    end

    def add_font(key : String, path_key : String, size : Float32)
      @tasks << AssetTask.new(:Font, key, path_key, size)
    end

    def add_dialog(path_key : String)
      @tasks << AssetTask.new(:Dialog, "", path_key)
    end

    def add_tile_map(key : String, path_key : String)
      @tasks << AssetTask.new(:TileMap, key, path_key)
    end

    def start_async(workers : Int32 = 4)
      @max_workers = workers
      @progress.set_total(@tasks.size)
      
      @task_mutex.synchronize do
        @tasks.each { |t| @task_queue.push(t) }
        @tasks.clear
      end

      @max_workers.times do
        @worker_threads << Thread.new { worker_loop }
      end
    end

    def update
      # Main thread: convert surfaces to textures
      # Process a limited number of surfaces per frame to keep UI responsive
      count = 0
      while count < @max_assets_per_frame
        task_data = @surface_mutex.synchronize do
          @surface_queue.empty? ? nil : @surface_queue.shift
        end

        break unless task_data
        
        key, surface = task_data
        # SDL3: Create texture from surface (must be on main thread)
        TextureManager.instance.load_from_surface(key, surface)
        surface.destroy
        @progress.increment_loaded
        puts "GSDL::Loader: Processed texture '#{key}' (#{progress.loaded_count}/#{progress.total_count})"
        count += 1
      end
    end

    def progress : Progress
      @progress
    end

    def complete? : Bool
      # Complete when all assets are loaded by workers AND all surfaces are processed by main thread
      @progress.complete? && @surface_mutex.synchronize { @surface_queue.empty? }
    end

    private def worker_loop
      loop do
        task = @task_mutex.synchronize do
          @task_queue.empty? ? nil : @task_queue.shift
        end

        break unless task
        begin
          load_single_asset(task)
        rescue ex
          puts "GSDL::Loader: Error loading asset '#{task.path_key}': #{ex.message}"
          # We still increment progress so complete? can eventually return true,
          # or maybe we should have a failed count
          @progress.increment_loaded
        end
      end
    end

    private def load_single_asset(task : AssetTask)
      case task.type
      when AssetType::Texture
        # Background: Load Surface from file/pack
        path = task.path_key
        surface = uninitialized Surface
        {% if flag?(:release) %}
          data = AssetManager.load_raw_data(path)
          io = SDL3::IOStream.from_memory(data, data.size)
          sdl_surface = SDL3::Image.load_io(io, close_io: true)
          surface = Surface.new(sdl_surface)
        {% else %}
          full_path = GSDL::AssetManager.asset_path + path
          sdl_surface = SDL3::Image.load(full_path)
          surface = Surface.new(sdl_surface)
        {% end %}

        @surface_mutex.synchronize do
          @surface_queue.push({task.key, surface})
        end
      when AssetType::Audio
        AudioManager.load(task.key, task.path_key)
      when AssetType::Font
        FontManager.load(task.key, task.path_key, task.size)
      when AssetType::Dialog
        DialogManager.load(task.path_key)
      when AssetType::TileMap
        TileMapManager.load(task.key, task.path_key)
      end
      unless task.type == AssetType::Texture
        @progress.increment_loaded
        puts "GSDL::Loader: Loaded #{task.type} '#{task.key}' (#{progress.loaded_count}/#{progress.total_count})"
      end
    end
  end
end
