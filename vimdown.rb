#!/usr/bin/env ruby

require 'artii'

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
  match = slide.match( /##\s*(.*)/ )
  if !match
    match = slide.match( /#\s*(.*)/ )
    header = slant.asciify match[1] if match
  else
    header = smslant.asciify match[1]
  end
  rest = slide.match( /[^\n]*\n([\s\S\n]*)/m )

  code_height = 0
  code_lang = ''
  if rest
    code = rest[1].match( /```([^\n]*)\n.*\n```/m )
    if code
      code_height = code[0].split("\n").length - 2
      code_lang = code[1]
      rest = rest[1].gsub( /\n```[^\n]*\n/, '' ).gsub( /\n```/, '' )
    else
      rest = rest[1]
    end
  end

  new_slide += header + "\n" if header
  new_slide += rest if rest
  new_slide += "\n" * 20


  script += "b #{i+1}\n"
  if code_height > 0
    start = new_slide.index(rest)
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

File.open("presentation/z.vim", "w") do |file|
  file.write script
end

exec 'vim presentation/*.md -S presentation/z.vim'
