#!/usr/bin/env ruby

require 'artii'
require 'erb'
require 'redcarpet'

$nl = "\n"

module Vimdeck
  # Helper methods for ascii art conversion
  class Ascii
    def self.header(text, type)
      if font_name = Vimdeck::Slideshow.options[:header_font]
        begin
          font = Artii::Base.new :font => font_name
        rescue
          raise "Incorrect figlet font name"
        end
      else
        if type == "large"
          font = Artii::Base.new :font => 'slant'
        else
          font = Artii::Base.new :font => 'smslant'
        end
      end

      font.asciify(text)
    end

    def self.image(img)
      # a = AsciiArt.new(img)
      # a.to_ascii_art width: 30
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
      :autolink,
      :underline, :raw_html,
      :strikethrough,
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

    def code_span(text)
      return "`#{text}`"
    end

    def emphasis(text)
      return "*#{text}*"
    end

    def double_emphasis(text)
      return "**#{text}**"
    end

    def triple_emphasis(text)
      return "***#{text}***"
    end

    def list(content, type)
      if type == :unordered
        "<!~#{content}~!>#{$nl}#{$nl}"
      else
        "<@~#{content}~@>#{$nl}#{$nl}"
      end
    end

    def header(title, level)
      margin = Vimdeck::Slideshow.options[:header_margin]
      linebreak = margin ? "#{$nl}" * margin : "#{$nl}"
      if !Vimdeck::Slideshow.options[:no_ascii]
        case level
        when 1
          heading = Vimdeck::Ascii.header(title, "large")
          if Vimdeck::Slideshow.options[:no_indent]
            heading = "    " + heading.gsub( /\r\n?|\n/, "#{$nl}    " ) + linebreak
          else
            heading + linebreak
          end
        when 2
          heading = Vimdeck::Ascii.header(title, "small")
          if Vimdeck::Slideshow.options[:no_indent]
            heading = "    " + heading.gsub( /\r\n?|\n/, "#{$nl}    " ) + linebreak
          else
            heading + linebreak
          end
        end
      else
        title + "#{$nl}#{$nl}"
      end
    end

    def link(link, title, content)
      content
    end

    def paragraph(text)
      text + "#{$nl}#{$nl}"
    end

    def block_code(code, language)
      "```#{language}#{$nl}#{code}#{$nl}```"
    end

    def image(image, title, alt_text)
      # Vimdeck::Ascii.image(image)
    end
  end

  class Slideshow
    @options = {}

    def self.options
      @options
    end

    def self.slide_padding
      @options[:no_indent] ? "" : "        "
    end

    def self.script_template
      template = ERB.new(File.read(File.dirname(__FILE__) + "/templates/script.vim.erb"), nil, '-')
      template.result(binding)
    end

    def self.generate(filename, options)
      @options = options
      extension = options[:no_filetype] ? ".txt" : ".md"
      if options[:dos_newlines]
        $nl = "\r\n"
      end
      slides = File.read(filename)

      renderer = Redcarpet::Markdown.new(Vimdeck::Render, :fenced_code_blocks => true)
      Dir.mkdir("presentation") unless File.exists?("presentation")
      @buffers = []

      # Slide separator is 3 newlines
      slides = slides.split(/(?:\r\n?|\n)(?:\r\n?|\n)(?:\r\n?|\n)/)
      i = 0
      slides.each do |slide|
        # Pad file names with zeros. e.g. slide001.md, slide023.md, etc.
        slide_num = "%03d" % (i+1)
        slide = renderer.render(slide)

        regex = /\<\@\~(.*?)\~\@\>/m
        match = slide.match(regex)
        while match && match[1] && match.post_match do
          list = match[1].split(/\r\n?|\n/)
          j = 0
          list = list.map do |li|
            j += 1
            "#{j}. #{li}"
          end
          slide.sub!(regex, list.join($nl))
          match = match.post_match.match(regex)
        end

        regex = /\<\!\~(.*?)\~\!\>/m
        match = slide.match(regex)
        while match && match[1] && match.post_match do
          list = match[1].split(/\r\n?|\n/)
          list = list.map do |li|
            "\u2022 #{li}"
          end
          slide.sub!(regex, list.join($nl))
          match = match.post_match.match(regex)
        end

        # buffer gets stashed into @buffers array for script template
        # needs to track things like the buffer number, code highlighting
        # and focus/unfocus stuff
        buffer = {:num => i + 1}
        code_height = 0
        code = nil
        code = slide.match( /```([^\r\n]*)(\r\n?|\n).*(\r\n?|\n)```/m )
        if code
          buffer[:code] = []
          code_hash = { :language => code[1] }
          code_height = code[0].split(/\r\n?|\n/).length - 2
          code = code[0].gsub( /```[^\r\n]*(\r\n?|\n)/, '' ).gsub( /(\r\n?|\n)```/, '' )
          slide = slide.gsub( /```[^\r\n]*(\r\n?|\n)/, '' ).gsub( /(\r\n?|\n)```/, '' )

          if code_height > 0
            start = slide.index(code)
            start = slide[0..start].split(/\r\n?|\n/).length
            code_hash[:end] = code_height + start - 1
            code_hash[:start] = start
          end
          buffer[:code] << code_hash
        end

        # Prepending each line with slide_padding
        # Removing trailing spaces
        # Add newlines at end of the file to hide the slide identifier
        slide = slide_padding + slide.gsub( /\r\n?|\n/, "#{$nl}#{slide_padding}" ).gsub( / *$/, "" ) + ($nl * 80) + "slide #{slide_num}"

        # Buffers comments refers to items that need to be less focused/"unhighlighted"
        # We add a regex to the vimscript for each slide with "comments"
        # We use the hidden slide identifier to differentiate between slides
        regex = /\{\~(.*?)\~\}/m
        match = slide.match(regex)
        buffer[:comments] = []
        while match && match[1] && match.post_match do
          slide.sub!(regex, match[1])
          pattern = match[1] + "||(||_.*slide #{slide_num}||)||@="
          buffer[:comments] << pattern.gsub(/\r\n?|\n/, "||n").gsub(/\[/, "||[").gsub(/\]/, "||]").gsub(/\|/, "\\").gsub(/\"/, "\\\"")
          match = match.post_match.match(regex)
        end

        File.open("presentation/slide#{slide_num}#{extension}", "w") do |file|
          file.write("#{slide}#{$nl}")
        end

        @buffers << buffer
        i += 1
      end

      File.open("presentation/script.vim", "w") do |file|
        file.write script_template
      end
    end

    def self.open
      extension = @options[:no_filetype] ? ".txt" : ".md"
      editor = options[:editor] || "vim"
      exec "#{editor} presentation/*#{extension} -S presentation/script.vim"
    end

    def self.start(filename, options)
      generate(filename, options)
      open
    end
  end
end
