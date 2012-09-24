#--
# Lackey set to OCTGN set package
# Copyright (c) 2012 Raohmaru

# Permission is hereby granted, free of charge, to any person obtaining
# a copy of this software and associated documentation files (the
# "Software"), to deal in the Software without restriction, including
# without limitation the rights to use, copy, modify, merge, publish, 
# distribute, sublicense, and/or sell copies of the Software, and to
# permit persons to whom the Software is furnished to do so, subject to
# the following conditions:

# The above copyright notice and this permission notice shall be
# included in all copies or substantial portions of the Software.

# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
# EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
# MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
# IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
# CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
# TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
# SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
#++

require 'rubygems'
require 'uuidtools'
require 'builder/xmlmarkup'
require 'RMagick'
# Ruby < 1.9 doesn't support ordered hashes
require 'active_support/ordered_hash' if RUBY_VERSION < "1.9"

module Dvolatooc
  VERSION = "0.6.0"
  
  class << self
    
    def init(argv)
      @game_id      = '51ac5322-f399-4116-a38e-12573aba58ae'
      @game_version = '0.9.1'
      @set_version  = '1.0.0'
      
      @draw = Magick::Draw.new
      @style_dir = Dir.getwd + '/style/'
      @templates = Magick::ImageList.new(@style_dir+'thing.png', @style_dir+'action.png')
      @pics_dir = Dir.getwd + '/pics/'
      @pics_dir = nil unless FileTest.directory?(@pics_dir)
      @rules_cols = 0
      @flavor_cols = 0
      
      parseArgs(argv)
      checkArgs
      mkSetFolders
      createFiles
      writeFiles

      puts "Set '#{@set_name}' created\n"
      puts "Founded #{@cards_total} cards\n"
      puts "Files stored at #{@set_dir}"
    end
    
    def parseArgs(argv)
      usage = <<EOF

= DVOLATOOC! =

A simple tool to convert Dvorak decks in Lackey format to an OCTGN set.

Usage:
    dvolatooc input_file [options]

Example:
    dvolatooc lackey.txt
    dvolatooc lackey.txt -n "Programming deck" -c PRG
    dvolatooc svl.txt -n Supervillains! -v 1.0.5

Arguments:

    input_file    Lackey set definiton of an Dvorak deck

Options:

    --help        Display this information.
    --version     Display version number and exit.

    Set options:

    -gi <UUID>    Overrides the id of the target Dvorak OCTGN game.
                  It must be a canonical UUID string
    -gv <#.#.#>   Overrides the version of the target Dvorak OCTGN game
    -n            Name of the set
    -v <#.#.#>    Define a version for this set. Defaults to #{@game_version}
EOF
      unless argv.empty?
        while arg = argv.shift
          case arg
            when /\A--gameid\z/, /\A-gi\z/
              @game_id = argv.shift
            when /\A--gameversion\z/, /\A-gv\z/
              @game_version = argv.shift
            when /\A--setname\z/, /\A-n\z/
              @set_name = argv.shift
            when /\A--setversion\z/, /\A-v\z/
              @set_version = argv.shift
            when /\A--version\z/
              printAndExit "Dvolatooc #{VERSION}"
            when /\A--help\z/, /\A--./
              printAndExit usage
            else
              @filename = arg if @filename.nil?
          end
        end
      else
        printAndExit usage
      end
    end
    
    def checkArgs
      if @filename.nil?
        printAndExit "Input file required"
      elsif !File.exist?(@filename)
        printAndExit "File #{@filename} was not found"
      end
      
      @file = File.new(@filename)
      # Gets first card on the set (it is at the 2nd line)
      2.times{@file.gets}
      row = $_.split "\t"
      @num_cards = @file.readlines.length+1
      @file.rewind
      
      if row.length < 8
        printAndExit "Input file is not a valid Lackey deck set"
      end
      
      # Gets the real set name from the input set definition
      @set_name_real = row[1]      
      
      if @set_name.nil? || @set_name.empty?
        @set_name = @set_name_real
      end
      
      # Gets the set code from the set name, as an acronym
      @set_code = ''
      words = @set_name_real.upcase.split(/_| /)
      words.map { |w|
        next if ["THE","AND","AN","A","OF","TO","IS","DECK"].include? w
        @set_code += w[0,1]
        break if @set_code.length >= 4
      }
      
      # Code too short
      if words[-1].length > 1
        i = 1
        while @set_code.length < 3
          letter = words[-1][i,1]
          break if letter.nil?
          @set_code += letter
          i += 1
        end
      end
    end
    
    def createFiles
      @xml_set = ''  # Objects to save the xml string
      @xml_res = ''
      i = 1
      
      # key => card name, val => UUID object
      if RUBY_VERSION < "1.9"
        cards = ActiveSupport::OrderedHash.new
      else
        cards = {}
      end
      
      # Builds up the XML set definition
      # <https://github.com/kellyelton/OCTGN/wiki/Xml-Set-Description>
      xml = Builder::XmlMarkup.new( :target => @xml_set, :indent => 4 )
      xml.instruct! :xml, :standalone => 'yes'
      # Add <set> child node
      xml.set(
        # <set> attributes
        :name        => @set_name,
        :id          => UUIDTools::UUID.parse_raw(@set_name_real),
        :gameId      => @game_id,
        :gameVersion => @game_version,
        :version     => @set_version
      ) {
        # Add <cards> child node
        xml.cards {
          # Read each line of the txt file input
          @file.each_with_index do |line, index|
            next if index == 0  # Skip 1st line since are columns names
            card = Card.new(line, i)
            next unless cards[card.name].nil?  # Skip duplicated cards
            cards[card.name] = UUIDTools::UUID.parse_raw( @set_name_real+card.name )
            
            xml.card(
              # <card> attributes
              :name => card.name,
              :id   => cards[card.name]
            ) {
              xml.property :name => 'Type',     :value => card.type
              xml.property :name => 'Subtype',  :value => card.subtype
              xml.property :name => 'Rarity',   :value => card.rarity
              xml.property :name => 'Value',    :value => card.value
              xml.property :name => 'Rules',    :value => card.rules
              xml.property :name => 'Flavor',   :value => card.flavor
              xml.property :name => 'Artist',   :value => card.artist
              xml.property :name => 'Number',   :value => card.number
              xml.property :name => 'Creator',  :value => card.creator
            }
            
            createCardImage(card)
            
            i += 1
          end  # file.each()
        }  # End of xml.cards
      }  # End of xml.set
      
      # Write resources XML file
      i = 1
      xml = Builder::XmlMarkup.new( :target => @xml_res, :indent => 4 )
      xml.instruct! :xml
      # Add <Relationships> child node
      xml.Relationships(
        # <Relationships> attributes
        :xmlns      => 'http://schemas.openxmlformats.org/package/2006/relationships'
      ) {
        #<Relationship Target='/cards/001.jpg' Id='Ce3db6eec6b1a4c9b83cd456d7cb8e001' Type='http://schemas.octgn.org/picture' />
        cards.each { |k,v|
          # Add <Relationship> child node
          xml.Relationship(
            # <Relationship> attributes
            :Target => '/cards/' + sprintf("%03d", i) + '.jpg',
            :Id     => 'C' + v.hexdigest,
            :Type   => 'http://schemas.octgn.org/picture'
          )
          i += 1
        }  # cards.each
      }  # xml.Relationships
      
      @cards_total = i-1
    end
    
    def createCardImage(card)
      color = card.thing? ? '#4a4de5' : '#e65252'
      image = @templates[card.thing? ? 0 : 1].copy
      
      @draw.font = @style_dir+'font/EurostileT-Black.ttf'
      
      # Title
      #              draw, width, height, x, y, text
      @draw.pointsize = size = 30
      metrics = @draw.get_type_metrics(image, card.name)
      if metrics.width > 266
        @draw.pointsize = size = 30*266 / metrics.width
      end
      image.annotate(@draw, 266, 35, 30, 30+(30-size), card.name) {
        self.fill = 'white'
        self.gravity = Magick::NorthWestGravity
      }
      # Value
      unless card.value.empty?
        image.annotate(@draw, 38, 32, 304, 28, card.value) {
          self.fill = color
          self.pointsize = 30
          self.gravity = Magick::NorthGravity
        }
      end
      # Type
      image.annotate(@draw, 345, 22, 0, 74, card.supertype) {
        self.fill = 'white'
        self.pointsize = 18
        self.gravity = Magick::NorthEastGravity
      }
      # Rules
      unless card.rules.empty?
        @draw.font = @style_dir+'font/Ubuntu-Medium.ttf'
        @draw.pointsize = 17
        if @rules_cols == 0
          metrics = @draw.get_type_metrics(image, 'n')
          @rules_cols = (315 / metrics.width).floor + 4
        end
        rules = card.text_multiline(card.rules, @rules_cols)
        image.annotate(@draw, 315, 130, 30, 330, rules) {
          self.fill = 'black'
          self.gravity = Magick::NorthWestGravity
        }
      end
      # Flavor text
      unless card.flavor.empty?
        y = 330+10
        unless card.rules.empty?
          metrics = @draw.get_multiline_type_metrics(image, rules)
          y += metrics.height
        end
        @draw.font = @style_dir+'font/Ubuntu-Italic.ttf'
        @draw.pointsize = 16
        if @flavor_cols == 0
          metrics = @draw.get_type_metrics(image, 'n')
          @flavor_cols = (315 / metrics.width).floor + 4
        end
        image.annotate(@draw, 315, 130, 30, y, card.text_multiline(card.flavor, @flavor_cols)) {
          self.fill = 'black'
          self.gravity = Magick::NorthWestGravity
        }
      end
      # Creator
      @draw.font = @style_dir+'font/Ubuntu-Medium.ttf'
      creator = "Card by #{card.creator}"
      creator += ". Art by #{card.artist}" unless card.artist.empty?
      image.annotate(@draw, 250, 14, 15, 500, creator) {
        self.fill = 'black'
        self.pointsize = 12
        self.gravity = Magick::NorthWestGravity
      } 
      # Number
      image.annotate(@draw, 360, 14, 0, 500, @set_code+"-#{card.number}/#{@num_cards}") {
        self.gravity = Magick::NorthEastGravity
      }
      
      # Picture
      if @pics_dir
        file = nil
        ['.jpg','.jpeg','.gif','.png'].each{ |ext|
          file1 = @pics_dir+card.number.to_s+ext
          file2 = @pics_dir+card.name+ext
          if FileTest.file?(file1)
            file = file1
            break
          elsif FileTest.file?(file2)
            file = file2
          end
        }
        
        unless file.nil?
          pict = Magick::ImageList.new(file)
          pict.resize_to_fill!(315, 218)
          image.composite!(pict, 30, 104, Magick::OverCompositeOp)
        end
      end
      
      image.write('cards/'+sprintf("%03d", card.number)+'.jpg')
    end
    
    def mkSetFolders
      # Folder structure of the OCTGN set
      @set_dir = @set_code+'-v'+@set_version
      Dir.mkdir(@set_dir) unless FileTest.directory?(@set_dir)
      Dir.chdir(@set_dir)
      Dir.mkdir('_rels') unless FileTest.directory?('_rels')
      Dir.mkdir('cards') unless FileTest.directory?('cards')
    end
    
    def writeFiles
      # Write the XML set definition
      file = File.new( @set_code+".xml", "w:UTF-8" )
      file.puts( @xml_set )
      file.close
      
      # Write [Content_Types].xml file
      file = File.new( "[Content_Types].xml", "w" )
      file.puts <<"EOF"
<Types xmlns="http://schemas.openxmlformats.org/package/2006/content-types">
  <Default Extension="rels" ContentType="application/vnd.openxmlformats-package.relationships+xml" />
  <Default Extension="jpg" ContentType="image/jpeg" />
  <Default Extension="wdp" ContentType="image/vnd.ms-photo" />
  <Default Extension="png" ContentType="image/png" />
  <Default Extension="xml" ContentType="text/xml" />
  <Default Extension="o8d" ContentType="octgn/deck" />
</Types>
EOF
      file.close

      # Write relationships XML file
      file = File.new( "_rels/.rels", "w" )
      file.puts <<"EOF"
<Relationships xmlns='http://schemas.openxmlformats.org/package/2006/relationships'>
  <Relationship Target='/#{@set_code}.xml' Id='def' Type='http://schemas.octgn.org/set/definition' />
</Relationships>
EOF
      file.close
      
      # Write resources XML file
      file = File.new( "_rels/#{@set_code}.xml.rels", "w" )
      file.puts( @xml_res )
      file.close
    end
    
    def printAndExit(msg)
      puts msg
      exit 0
    end
    
  end  # class << self
end

class Card
  
  attr_reader :name, :supertype, :type, :subtype, :rarity, :value, :rules, :flavor, :artist, :number, :creator
  
	def initialize(raw, number)
    # Lackey columns:
    # 0:Name  1:Set  2:ImageFile  3:Type  4:CornerValue  5:Text  6:FlavorText  7:Creator
    raw = raw.split "\t"  # Split by tab char
    type = raw[3].split /\s\-\s/
    
    @name = raw[0].strip
    @type = type[0].strip
    @subtype = type.length > 1 ? type[1..-1].join(' - ') : ''
    @supertype = @type + (@subtype.empty? ? '' : ' - '+@subtype)
    @rarity = 'Common'
    @value = raw[4].strip
    @rules = raw[5].strip
    @flavor = raw[6].strip
    @artist = ''
    @number = number
    @creator = raw[7].nil? ? '' : raw[7].rstrip
	end
  
  def thing?
    return /thing|objeto/i.match(@type) != nil
  end
  
  def action?
    return /action|acción/i.match(@type) != nil
  end
  
  def text_multiline(text, cols)
    m = []
    line = ''
    text.split(' ').each do |word|
      if (line + word).length < cols
        line += word + ' '
      else
        m.push line
        line = word + ' '
      end
    end
    m.push line
    
    return m.join '\n'
  end
  
end

if File.basename(__FILE__) == File.basename($0)
  Dvolatooc.init(ARGV)
end