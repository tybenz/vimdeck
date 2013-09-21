#!/usr/bin/env ruby

require 'artii'
require 'asciiart'
require 'erb'
require 'redcarpet'

module Vimdeck
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

  class Render < Redcarpet::Render::Base
    # Methods where the first argument is the text content
    [
      # block-level calls
      :block_quote,
      :block_html, :list, :list_item,

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

    def header(title, level)
      case level
      when 1
        Vimdeck::artii(title, "large") + "\n"

      when 2
        Vimdeck::artii(title, "small") + "\n"
      end
    end

    def link(link, title, content)
      content
    end

    def paragraph(text)
      text + "\n"
    end

    def block_code(code, language)
      "```#{language}\n#{code}\n```"
    end

    def image(image, title, alt_text)
      Vimdeck::ascii_art(image)
    end
  end

  class Slideshow
    def self.slide_padding
      "        "
    end

    def self.script_template
      template = ERB.new(File.read(File.dirname(__FILE__) + "/templates/script.vim.erb"))
      template.result(binding)
    end

    def self.generate(filename)
      slides = File.read(filename)

      slides = slides.split("\n\n\n")
      renderer = Redcarpet::Markdown.new(Vimdeck::Render, :fenced_code_blocks => true)
      @buffers = []

      Dir.mkdir("presentation") unless File.exists?("presentation")

      i = 0
      slides.each do |slide|
        slide_num = "%03d" % (i+1)
        slide = renderer.render(slide)

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

        slide = slide_padding + slide.gsub( /\n/, "\n#{slide_padding}" ).gsub( / *$/, "" ) + ("\n" * 80) + "slide #{i+1}"

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

    def self.start(filename)
      generate(filename)
      open
    end
  end
end
