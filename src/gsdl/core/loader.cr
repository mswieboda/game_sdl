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
      FontOld
      Font
      Dialog
      TileMap
    end

    record AssetTask, type : AssetType, key : String, path_key : String, size : Float32 = 0_f32, outline : Int32 = 0
    record AssetResult, task : AssetTask, bytes : Bytes

    @tasks = Array(AssetTask).new
    @progress = Progress.new

    @task_queue = Deque(AssetTask).new
    @task_mutex = Mutex.new

    @result_queue = Deque(AssetResult).new
    @result_mutex = Mutex.new

    # Backpressure: Maximum number of loaded results waiting for the main thread
    @max_queued_results = 20

    @worker_threads = Array(Thread).new
    @max_workers = 4
    property max_assets_per_frame : Int32 = 10

    def initialize
    end

    def add_texture(key : String, path_key : String)
      @tasks << AssetTask.new(AssetType::Texture, key, path_key)
    end

    def add_audio(key : String, path_key : String)
      @tasks << AssetTask.new(AssetType::Audio, key, path_key)
    end

    def add_font_old(key : String, path_key : String, size : Float32)
      @tasks << AssetTask.new(AssetType::FontOld, key, path_key, size)
    end

    def add_font(path_key : String, size : Num, outline : Int32)
      ext = File.extname(path_key)
      name = File.basename(path_key, ext)

      # NOTE: path_key isn't used later, but might as well include it, instead of ""
      @tasks << AssetTask.new(AssetType::Font, name, path_key, size, outline)
    end

    def add_dialog(path_key : String)
      @tasks << AssetTask.new(AssetType::Dialog, "", path_key)
    end

    def add_tile_map(key : String, path_key : String)
      @tasks << AssetTask.new(AssetType::TileMap, key, path_key)
    end

    def add_tasks(tasks : Array(AssetTask))
      @tasks.concat(tasks)
    end

    def busy? : Bool
      !complete? && (@task_mutex.synchronize { !@task_queue.empty? } || @result_mutex.synchronize { !@result_queue.empty? })
    end

    def start_async(workers : Int32 = 4)
      # Cap workers to prevent resource exhaustion
      @max_workers = workers.clamp(1, 8)
      @progress.set_total(@tasks.size)

      @task_mutex.synchronize do
        @tasks.each { |t| @task_queue.push(t) }
        @tasks.clear
      end

      @max_workers.times do |i|
        @worker_threads << Thread.new { worker_loop }
      end
    end

    def update
      # Main thread: convert raw bytes to GSDL objects
      count = 0
      while count < @max_assets_per_frame
        result = @result_mutex.synchronize do
          @result_queue.empty? ? nil : @result_queue.shift
        end

        break unless result

        task = result.task
        bytes = result.bytes

        begin
          case task.type
          when AssetType::Texture
            io = SDL3::IOStream.from_memory(bytes, bytes.size)
            sdl_surface = SDL3::Image.load_io(io, close_io: true)
            TextureManager.load_from_surface(task.key, Surface.new(sdl_surface))
          when AssetType::Audio
            io = SDL3::IOStream.from_memory(bytes, bytes.size)
            AudioManager.load_from_memory(task.key, io)
          when AssetType::FontOld
            io = SDL3::IOStream.from_memory(bytes, bytes.size)
            FontOldManager.load_from_memory(task.key, io, task.size)
          when AssetType::Font
            FontManager.load_from_memory(task.key, bytes, task.size, task.outline)
          when AssetType::Dialog
            DialogManager.load(task.path_key)
          when AssetType::TileMap
            TileMapManager.load_from_memory(task.key, bytes)
          end
        rescue ex
          puts "GSDL::Loader: Error registering asset '#{task.path_key}': #{ex.message}"
        ensure
          @progress.increment_loaded
        end

        count += 1
      end
    end

    def progress : Progress
      @progress
    end

    def complete? : Bool
      @progress.complete? && @result_mutex.synchronize { @result_queue.empty? }
    end

    private def worker_loop
      loop do
        # 1. Backpressure: Check if result queue is full
        # If too many results are pending, wait a bit so we don't exhaust memory
        # Using LibC.nanosleep because standard sleep is fiber-aware and can cause crashes in raw threads
        if @result_mutex.synchronize { @result_queue.size } >= @max_queued_results
          ts = LibC::Timespec.new
          ts.tv_sec = 0
          ts.tv_nsec = 10_000_000 # 10ms
          LibC.nanosleep(pointerof(ts), nil)
          next
        end

        # 2. Get next task
        task = @task_mutex.synchronize do
          @task_queue.empty? ? nil : @task_queue.shift
        end

        break unless task

        begin
          load_single_asset_io(task)
        rescue ex
          # Avoid puts in threads as it's not thread-safe in Crystal's default scheduler
          @progress.increment_loaded
        end
      end
    end

    private def load_single_asset_io(task : AssetTask)
      path = task.path_key

      # We must ensure the bytes are copied into a stable buffer because
      # File.read(path).to_slice returns a pointer to a temporary string that can be GC'd
      bytes = if AssetManager.initialized?
        AssetManager.load_raw_data(path)
      else
        File.open(AssetManager.asset_path + path) do |file|
          slice = Bytes.new(file.size.to_i)
          file.read_fully(slice)
          slice
        end
      end

      @result_mutex.synchronize do
        @result_queue.push(AssetResult.new(task, bytes))
      end
    end
  end
end
