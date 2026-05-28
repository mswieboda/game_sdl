require "./hbox"

module GSDL
  module UI
    class StatusBar < HBox
      def initialize(
        width = FillParent,
        height = FitContent,
        spacing = 0,
        @background_color = Color::DarkerGray,
        @anchor = Anchor::BottomLeft,
      )
        super(width: width, height: height, spacing: spacing)
      end
    end
  end
end
