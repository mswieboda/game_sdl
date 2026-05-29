require "./hbox"

module GSDL
  module UI
    class StatusBar < HBox
      def initialize(
        width = FillParent,
        height = FitContent,
        spacing = 0,
        @background_color = Color::DarkerGray,
        anchor = Anchor::BottomLeft,
        flex : UInt8 = 0_u8,
        padding = Spacing.new(all: 0),
        margin = Spacing.new(all: 0),
      )
        super(
          width: width,
          height: height,
          spacing: spacing,
          anchor: anchor,
          flex: flex,
          padding: padding,
          margin: margin
        )
      end
    end
  end
end
