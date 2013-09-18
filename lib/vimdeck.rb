require 'artii'
require 'asciiart'
require 'erb'

module Vimdeck
  @slide_delimiter = "\n\n\n"

  def self.artii(text, type)
    if type == "large"
      font = Artii::Base.new :font => 'slant'
    else
      font = Artii::Base.new :font => 'smslant'
    end

    font.asciify(text)
  end

  def self.ascii_art(img)
    AsciiArt.new(img)
  end

  def self.script_template
    @template.result(binding)
  end

  def self.create_slides(file)
    slides = File.read(file).split(@slide_delimiter)

    @template = ERB.new(File.read(File.dirname(__FILE__) + "/templates/script.vim.erb"))
    @buffers = []

    Dir.mkdir("presentation") unless File.exists?("presentation")
    slides.each_with_index do |slide, i|
      new_slide = ''
      headers = []

      slide.each_line do |line|
        match = line.match( /##\s*(.*)/ )
        if match && match[1]
          headers << artii(match[1], "small")
        else
          match = line.match( /#\s*(.*)/ )
          if match && match[1]
            headers << artii(match[1], "large")
          end
        end
      end

      rest = slide.gsub( /#+\s*(.*)\n/, '' )
      images = rest.scan( /\!\[\]\([^\(\)]*\)/ )
      text = rest.split( /\!\[\]\([^\(\)]*\)/ )

      if images.length > 0
        rest = ''
        images.each_with_index do |img,j|
          rest += text[j] if text[j]

          a = AsciiArt.new(img.match(/\(([^\(\)]*)\)/)[1])
          rest += a.to_ascii_art width: 30
        end
      end

      buffer = {:num => i + 1}
      code_height = 0
      code = nil
      if rest
        code = rest.match( /```([^\n]*)\n.*\n```/m )
        if code
          buffer[:code] = { :language => code[1] }
          code_height = code[0].split("\n").length - 2
          code = code[0].gsub( /```[^\n]*\n/, '' ).gsub( /\n```/, '' )
          rest = rest.gsub( /```[^\n]*\n/, '' ).gsub( /\n```/, '' )
        end
      end

      headers.each do |h|
        new_slide += h + "\n"
      end
      new_slide += rest if rest
      new_slide += "\n" * 80

      if code_height > 0
        start = new_slide.index(code)
        start = new_slide[0..start].split("\n").length
        buffer[:code][:end] = code_height + start - 1
        buffer[:code][:start] = start
      end

      spaces = "           "
      new_slide = new_slide.gsub( /\n/, "\n#{spaces}" )
      new_slide = spaces + new_slide
      new_slide = new_slide.gsub( / *\n/, "\n" ).gsub( / *$/, '' )


      File.open("presentation/slide#{i}.md", "w") do |file|
        file.write new_slide
      end

      @buffers << buffer
    end

    File.open("presentation/script.vim", "w") do |file|
      file.write script_template
    end
  end

  def self.open_vim
    exec 'vim presentation/*.md -S presentation/script.vim'
  end

  def self.slideshow(file)
    create_slides(file)
    open_vim
  end
end
