module GSDL
  class ColorScheme
    alias Value = String | Color

    @@colors = {
      :ui_text   => Color::White,
      :ui_bg     => Color::Black,
      :main      => Color::Blue,
      :alt       => Color::Gray,
      :highlight => Color::Yellow,
      :game_bg   => Color::Black,
      :border    => Color::White,
      :success   => Color::Green,
      :danger    => Color::Red,
    } of Symbol => Color

    def self.set(key : Symbol, value : Value)
      @@colors[key] = Color.parse(value)
    end

    def self.get(key : Symbol) : Color
      @@colors[key]? || Color::White
    end

    def self.get(key : Symbol, default : Color) : Color
      @@colors[key]? || default
    end

    def self.configure(values : Hash(Symbol, Value))
      values.each do |k, v|
        set(k, v)
      end
    end

    # Allows for a cleaner syntax: ColorScheme.configure(ui_text: "#000", ui_bg: "#FFF")
    macro configure(**options)
      {% for key, value in options %}
        GSDL::ColorScheme.set({{key.symbolize}}, {{value}})
      {% end %}
    end
  end
end
