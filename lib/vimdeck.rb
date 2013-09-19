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
    a = AsciiArt.new(img)
    a.to_ascii_art width: 30
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
      code_block = false

      slide.each_line do |line|
        match = line.match( /```(.*)$/ )
        if !code_block && match && match[1]
          code_block = true
        elsif code_block && line.match( /```/ )
          code_block=false
        elsif !code_block
          match = line.match( /##\s*(.*)/ )
          if match && match[1]
            slide.sub!( match[0], artii(match[1], "small") )
          else
            match = line.match( /#\s*(.*)/ )
            if match && match[1]
              slide.sub!( match[0], artii(match[1], "large") )
            else
              match = line.match( /\!\[\]\(([^\(\)]*)\)/ )
              if match && match[1]
                slide.sub!(match[0], self.ascii_art(match[1]))
              end
            end
          end
        end
      end

      buffer = {:num => i + 1}
      code_height = 0
      code = nil
      code = slide.match( /```([^\n]*)\n.*\n```/m )
      if code
        buffer[:code] = { :language => code[1] }
        code_height = code[0].split("\n").length - 2
        code = code[0].gsub( /```[^\n]*\n/, '' ).gsub( /\n```/, '' )
        slide = slide.gsub( /```[^\n]*\n/, '' ).gsub( /\n```/, '' )

        if code_height > 0
          start = slide.index(code)
          start = slide[0..start].split("\n").length
          buffer[:code][:end] = code_height + start - 1
          buffer[:code][:start] = start
        end
      end

      slide += "\n" * 80
      slide += "slide #{i+1}"

      spaces = "           "
      slide = slide.gsub( /\n/, "\n#{spaces}" )
      slide = spaces + slide
      slide = slide.gsub( / *\n/, "\n" ).gsub( / *$/, '' )

      regex = /\{\~(.*?)\~\}/m
      match = slide.match(regex)
      buffer[:comments] = []
      while match && match[1] && match.post_match do
        slide.sub!(regex, match[1])
        pattern = match[1] + "||(||_.*slide #{i+1}||)||@="
        buffer[:comments] << pattern.gsub(/\n/, "||n").gsub(/\[/, "||[").gsub(/\]/, "||]").gsub(/\|/, "\\").gsub(/\"/, "\\\"")
        match = match.post_match.match(regex)
      end

      filenum = "%03d" % (i+1)

      File.open("presentation/slide#{filenum}.md", "w") do |file|
        file.write slide
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
