#!/usr/bin/env ruby

require 'artii'
require 'asciiart'

slant = Artii::Base.new :font => 'slant'
smslant = Artii::Base.new :font => 'smslant'

slides = File.read('slides.md')

slides = slides.split( "\n\n\n" )
new_slides = []
script = "noremap <PageUp> :bp<CR>\n"
script += "noremap <Left> :bp<CR>\n"
script += "noremap <PageDown> :bn<CR>\n"
script += "noremap <Right> :bn<CR>\n"

slides.each_with_index do |slide, i|
  new_slide = ''
  headers = []

  slide.each_line do |line|
    match = line.match( /##\s*(.*)/ )
    if match && match[1]
      headers << smslant.asciify(match[1])
    else
      match = line.match( /#\s*(.*)/ )
      if match && match[1]
        headers << slant.asciify(match[1])
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

  code_height = 0
  code_lang = ''
  code = nil
  if rest
    code = rest.match( /```([^\n]*)\n.*\n```/m )
    if code
      code_height = code[0].split("\n").length - 2
      code_lang = code[1]
      rest = rest.gsub( /```[^\n]*\n/, '' ).gsub( /\n```/, '' )
      code = code[0].gsub( /```[^\n]*\n/, '' ).gsub( /\n```/, '' )
    end
  end

  headers.each do |h|
    new_slide += h + "\n"
  end
  new_slide += rest if rest
  new_slide += "\n" * 80


  script += "b #{i+1}\n"
  if code_height > 0
    puts code
    start = new_slide.index(code)
    start = new_slide[0..start].split("\n").length
    theend = code_height + start - 1

    script += "#{start},#{theend}SyntaxInclude #{code_lang}\n"
  end

  spaces = "           "
  new_slide = new_slide.gsub( /\n/, "\n#{spaces}" )
  new_slide = spaces + new_slide
  new_slide = new_slide.gsub( / *\n/, "\n" ).gsub( / *$/, '' )


  File.open("presentation/slide#{i}.md", "w") do |file|
    file.write new_slide
  end
end

script += "b 1\n"

File.open("presentation/script.vim", "w") do |file|
  file.write script
end

exec 'vim presentation/*.md -S presentation/script.vim'
