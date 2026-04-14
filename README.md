# game_sdl

Wrapper / helpers for making a game with SDL3 using [`sdl3.cr`](https://github.com/mswieboda/sdl3.cr)

## Template Repo

If you dont want to add everything manually, and want to use a boilerplate starting point, the https://github.com/mswieboda/template_game_sdl template repo is easy to rename quickly:

```
git clone git@github.com:mswieboda/template_game_sdl.git
cd template_game_sdl
crystal src/rename.cr
```

Follow the rename script prompts to rename all files, and class naming

to rename your root project folder to `my_foo_game` or whatever the file name you chose:

```
cd ../
mv template_game_sdl my_foo_game
cd my_foo_game
```

to install `game_sdl` and `sdl3.cr` dependencies:
```
shards install
```

to build your templated game:
```
make
```


## Installation

1. Install SDL3

follow [sdl3.cr install instructions](https://github.com/mswieboda/sdl3.cr) to get all the available SDL3 packages, image, TTY, mixer

2. Make your crystal app

```
crystal init my_foo_game
cd my_foo_game
```

3. Add the dependency to your `shard.yml`:

   ```yaml
   dependencies:
     game_sdl:
       github: mswieboda/game_sdl
   ```

4. Run `shards install`

```
shards install
```

5. Install GameSDL Tools

This step is optional, but required when you run `make release` or with any `--release` flagged crystal compile. In the release mode, GameSDL expects a `.pack` file of the packed assets (using in `build/assets.pack`)

for running the examples, use the Makefile
```
make packer
```

installs the `gsdl-packer` to your `./bin` directory which packages all assets into an `assets/assets.pack` binary file

see usage via:

```
./bin/gsdl-packer --help
```

can run via `make pack`

for consumers, add this by adding this to **your** `Makefile`:

```
$(PACKER_BIN):
  @echo "Building packer tool..."
  $(MKDIR_CMD) $(BIN_DIR)
  $(CRYSTAL_COMPILER) build lib/game_sdl/src/packer.cr -o $(BIN_DIR)/gsdl-packer --release --no-debug -p

packer: $(PACKER_BIN)

$(PACKER_FILE): $(PACKER_BIN)
  @echo "Packing assets via GameSDL packer..."
  ./$(PACKER_BIN)

pack: $(PACKER_FILE)
```

or use the https://github.com/mswieboda/template_game_sdl template repo to start from that has it included

## Release Packaging

To create a distribution-ready package for your game (on macOS, Windows, or Linux), you can use the built-in release helper.

This will build your game in release mode, bundle all assets into an `assets.pack`, and package everything into a platform-specific format (e.g., a `.app` bundle on macOS or a `.zip` file on Windows).

for consumers, add this by adding `release-package` (and aliases) to **your** `Makefile`: (you'll need to add the `release-package` command and the `release-package-[platform]` alias, or see `template_game_sdl`)

**Commands:**

- `make release-package GAME=your_game_name` (detects platform automatically)
- `make release-package-mac GAME=your_game_name`
- `make release-package-win GAME=your_game_name`
- `make release-package-linux GAME=your_game_name`

**Customization:**

You can customize the release by passing variables to `make` or by running the `release_helper.cr` script directly with arguments:

```bash
make release-package-mac GAME=my_game SRC=src/my_game.cr APP_NAME="My Awesome Game" VERSION=1.0.0 BUNDLE_ID=com.mygame.app
```

- `GAME`: The name of the resulting binary (default: `game`).
- `SRC`: Path to the source file (default: `src/main.cr`).
- `TARGET`: Target platform (`mac`, `win`, `linux`).
- `APP_NAME`: The name of your application (used for the bundle and binary name).
- `VERSION`: The version string (defaults to `shard.yml` version).
- `ICON`: Path to the icon file (e.g., `.icns` for macOS).
- `BUNDLE_ID`: macOS Bundle ID (e.g., `com.mygame.app`).
- `OUTPUT`: The directory to save the release package (default: `build/release`).

## Usage

```crystal
require "game_sdl"
```

## Documentation

To see full documentation of GameSDL, and SDL3 (included bindings library) you can run the `crystal docs` command, but specify the lib entry points, in correct order (SDL3 first, GSDL second, because GSDL depends on SDL3):

```
crystal docs lib/sdl3/src/sdl3.cr src/game_sdl.cr
```

or in your game:

```
crystal docs lib/sdl3/src/sdl3.cr lib/game_sdl/src/game_sdl.cr src/your_game_entry_point.cr
```

### Consumer App Release Package Makefile Instructions

If you are using `game_sdl` as a dependency in your own game (e.g., `your_sdl_game`), you can add these targets to your `Makefile` to use the built-in release helper:

```makefile
# Change 'your_sdl_game' to your actual binary name
GAME_NAME := your_sdl_game
# Change 'src/main.cr' to your game's entry point
GAME_SRC := src/main.cr

.PHONY: release-package release-package-mac release-package-win release-package-linux

release-package:
	@echo "Creating release package for $(GAME_NAME) (target: $(TARGET))..."
	mkdir -p build
	crystal run lib/game_sdl/src/gsdl/release_helper.cr -- \
		--example=$(if $(EXAMPLE),$(EXAMPLE),$(GAME_NAME)) \
		--src=$(if $(SRC),$(SRC),$(GAME_SRC)) \
		--target=$(TARGET) \
		$(if $(APP_NAME),--name="$(APP_NAME)") \
		$(if $(VERSION),--version=$(VERSION)) \
		$(if $(ICON),--icon=$(ICON)) \
		$(if $(BUNDLE_ID),--bundle-id=$(BUNDLE_ID)) \
		$(if $(OUTPUT),--output=$(OUTPUT))

release-package-mac:
	@$(MAKE) release-package TARGET=mac

release-package-win:
	@$(MAKE) release-package TARGET=win

release-package-linux:
	@$(MAKE) release-package TARGET=linux
```

### Dynamic Libraries

The release helper bundles the game binary, the `assets.pack`, and necessary dynamic libraries:
- **macOS:** Bundles `.dylib` files into `Contents/Frameworks/` and updates the binary's `@rpath`.
- **Windows:** Bundles all `.dll` files from the build directory into the same folder as the `.exe`.
- **Linux:** Currently requires system-wide libraries or manual bundling in the `.tar.gz`.

Unfortunately the `delegate` methods docs
 will not expand to full method signatures, so you'll need to infer wrapped classes like GSDL::Point that wraps SDL3::FPoint to see those method signatures. Eventually I plan to either document each delegate so the parameters and return types are clear, or fully wrap the methods themselves so it is even more clear.


## Contributing

1. Fork it (<https://github.com/mswieboda/game_sdl/fork>)
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request

### New Release

NOTE: this is for maintainers of the repo, to easily update tags and releases

To make a new release after PRs or features merged, make sure you bump the
version and push the tag. Currently this is done on `main` but might be automated with GitHub Actions/CI or done manually in PRs down the line.

script helper to bump version, commit, and tag:
```
./bump.cr patch|minor|major|specific-version
```
then
```
git push
```
and
```
git push --tags
```


## Contributors

- [Matt Swieboda](https://github.com/mswieboda) - creator and maintainer
