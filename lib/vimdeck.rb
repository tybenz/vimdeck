#!/usr/bin/env ruby

require 'artii'
require 'asciiart'
require 'erb'
require 'redcarpet'

module Vimdeck
  # Helper methods for ascii art conversion
  class Ascii
    def self.header(text, type)
      if type == "large"
        font = Artii::Base.new :font => 'slant'
      else
        font = Artii::Base.new :font => 'smslant'
      end

      font.asciify(text)
    end

    def self.image(img)
      a = AsciiArt.new(img)
      a.to_ascii_art width: 30
    end
  end

  # Custom Redcarpet renderer handles headers and images
  # Code blocks are ignored by the renderer because they have to be
  # measured for the vimscript, so parsing of the fenced code blocks
  # happens in the slideshow generator itself
  class Render < Redcarpet::Render::Base
    # Methods where the first argument is the text content
    [
      # block-level calls
      :block_quote,
      :block_html, :list_item,

      # span-level calls
      :autolink, :codespan, :double_emphasis,
      :emphasis, :underline, :raw_html,
      :triple_emphasis, :strikethrough,
      :superscript,

      # footnotes
      :footnotes, :footnote_def, :footnote_ref,

      # low level rendering
      :entity, :normal_text
    ].each do |method|
      define_method method do |*args|
        args.first
      end
    end

    def list(content, type)
      if type == :unordered
        "<!~#{content}~!>"
      else
        "<@~#{content}~@>"
      end
    end

    def header(title, level)
      if !Vimdeck::Slideshow.options[:no_ascii]
        case level
        when 1
          Vimdeck::Ascii.header(title, "large") + "\n"

        when 2
          Vimdeck::Ascii.header(title, "small") + "\n"
        end
      else
        title + "\n\n"
      end
    end

    def link(link, title, content)
      content
    end

    def paragraph(text)
      text + "\n\n"
    end

    def block_code(code, language)
      "```#{language}\n#{code}\n```"
    end

    def image(image, title, alt_text)
      Vimdeck::Ascii.image(image)
    end
  end

  class Slideshow
    @options = {}

    def self.options
      @options
    end

    def self.slide_padding
      "        "
    end

    def self.script_template
      template = ERB.new(File.read(File.dirname(__FILE__) + "/templates/script.vim.erb"))
      template.result(binding)
    end

    def self.generate(filename, options)
      @options = options
      slides = File.read(filename)

      renderer = Redcarpet::Markdown.new(Vimdeck::Render, :fenced_code_blocks => true)
      Dir.mkdir("presentation") unless File.exists?("presentation")
      @buffers = []

      # Slide separator is 3 newlines
      slides = slides.split("\n\n\n")
      i = 0
      slides.each do |slide|
        # Pad file names with zeros. e.g. slide001.md, slide023.md, etc.
        slide_num = "%03d" % (i+1)
        slide = renderer.render(slide)

        regex = /\<\@\~(.*)\~\@\>/m
        match = slide.match(regex)
        while match && match[1] && match.post_match do
          list = match[1].split("\n")
          j = 0
          list = list.map do |li|
            j += 1
            "#{j}. #{li}"
          end
          slide.sub!(regex, list.join("\n"))
          match = match.post_match.match(regex)
        end

        regex = /\<\!\~(.*)\~\!\>/m
        match = slide.match(regex)
        while match && match[1] && match.post_match do
          list = match[1].split("\n")
          list = list.map do |li|
            "\u2022 #{li}"
          end
          slide.sub!(regex, list.join("\n"))
          match = match.post_match.match(regex)
        end

        # buffer gets stashed into @buffers array for script template
        # needs to track things like the buffer number, code highlighting
        # and focus/unfocus stuff
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

        # Prepending each line with slide_padding
        # Removing trailing spaces
        # Add newlines at end of the file to hide the slide identifier
        slide = slide_padding + slide.gsub( /\n/, "\n#{slide_padding}" ).gsub( / *$/, "" ) + ("\n" * 80) + "slide #{i+1}"

        # Buffers comments refers to items that need to be less focused/"unhighlighted"
        # We add a regex to the vimscript for each slide with "comments"
        # We use the hidden slide identifier to differentiate between slides
        regex = /\{\~(.*?)\~\}/m
        match = slide.match(regex)
        buffer[:comments] = []
        while match && match[1] && match.post_match do
          slide.sub!(regex, match[1])
          pattern = match[1] + "||(||_.*slide #{i+1}||)||@="
          buffer[:comments] << pattern.gsub(/\n/, "||n").gsub(/\[/, "||[").gsub(/\]/, "||]").gsub(/\|/, "\\").gsub(/\"/, "\\\"")
          match = match.post_match.match(regex)
        end

        File.open("presentation/slide#{slide_num}.md", "w") do |file|
          file.write slide
        end

        @buffers << buffer
        i += 1
      end

      File.open("presentation/script.vim", "w") do |file|
        file.write script_template
      end
    end

    def self.open
      exec 'vim presentation/*.md -S presentation/script.vim'
    end

    def self.start(filename, options)
      generate(filename, options)
      open
    end
  end
end
