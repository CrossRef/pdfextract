module PdfExtract
  class AbstractView

    @@auto_colors = ["ff0000", "00ff00", "0000ff", "ffff00",
                     "ff7f00", "ffc0cb", "800080", "f0e68c",
                     "a52a2a"]

    def initialize pdf, filename
      @pdf = pdf
      @filename = filename
    end

    # Return renderable objects - those whose spatials method was
    # called explicitly.
    def objects
      @pdf.spatial_objects.reject { |type, _| not @pdf.explicit_call? type }
    end

    def auto_color
      @next_auto_color = 0 if @next_auto_color.nil?
      color = @@auto_colors[@next_auto_color]
      @next_auto_color = @next_auto_color.next
      color
    end

    def singular_name name
      name = name.sub /ies$/, 'y'
      name = name.sub /s$/, ''
    end
    
  end
end
