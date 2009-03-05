#!/usr/bin/env ruby

require 'date'  
require 'rubygems'
require 'rdiscount' 
require 'erb'

project_directory = ENV['TM_PROJECT_DIRECTORY']
active_filename = ENV['TM_FILENAME']
active_line_number = ENV['TM_LINE_NUMBER'].to_i 
default_layout = File.read(File.join(ENV['TM_BUNDLE_SUPPORT'], "layouts", "default.html.erb"))
selected_tag = ARGV[0] if ARGV 
  
File.open(active_filename) do |handle|
  note_report = []
  current_note = nil
  current_line = 0 
  
  handle.each_line do |line|
    current_line += 1
         
    # start a new current note
    if opening = /^(\d\d\d\d-\d\d-\d\d)\s+-\s+(.*)$/.match(line)
      current_note = {}
      open = true
      current_note[:start_line] = current_line
      current_note[:date] = Date.parse(opening[1])
      current_note[:title] = opening[2].strip
      current_note[:tags] = []
      current_note[:body] = ""  
      next
    end
                              
    # end the current note and push on to array to print out.
    if not current_note.nil? and closing = /^----\s*/.match(line)
      current_note[:end_line] = current_line

      if selected_tag and current_note[:tags].include?(selected_tag)
        note_report << current_note
      elsif !selected_tag and active_line_number <= current_note[:end_line] and active_line_number >= current_note[:start_line]
        note_report << current_note
      end
      current_note = nil         
      next
    end
     
    # append lines to body if we are not opening or closing
    unless current_note.nil?
      if tags = /^\s*\[(.*)\]\s*$/.match(line)
        current_note[:tags] << tags[1].split
        current_note[:tags].flatten!
      else
        current_note[:body] << line.gsub(/^#/, '###')
      end
    end
    
  end
   
  note_report.sort {|a, b| a[:date] <=> b[:date]}.each do |note|
    markdown_report = "\# #{note[:date]}\n\#\# #{note[:title]}\n"
    markdown_report << note[:body].strip
    markdown_report << "\n\n"                    
    markdown_report << "## Tags\n#{note[:tags].map {|tag| "* " + tag.downcase + "\n" }}" 
    
    if selected_tag
      @document_name = "Tag: #{selected_tag}"
    else 
      @document_name = note[:date]
    end
    @document_content = RDiscount.new(markdown_report).to_html
    puts ERB.new(default_layout).result
  end
  
end