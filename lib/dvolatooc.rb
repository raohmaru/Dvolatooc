#--
# Lackey set to OCTGN set package converter
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

require File.expand_path(File.dirname(__FILE__) + '/card')
require File.expand_path(File.dirname(__FILE__) + '/style')
require 'rubygems'
require 'uuidtools'
require 'builder/xmlmarkup'
# Ruby < 1.9 doesn't support ordered hashes
require 'active_support/ordered_hash' if RUBY_VERSION < "1.9"

module Dvolatooc
  VERSION = "0.6.5"

  module DIR
    BASE  = Dir.getwd
    STYLE = BASE + '/style/'
    PICS  = FileTest.directory?(BASE + '/pics/') ? BASE + '/pics/' : nil
  end

  class << self

    def init(argv)
      set = Struct.new(:code, :version, :name, :real_name, :game_id, :game_version, :num_cards)
      @set = set.new
      @set.game_id = '51ac5322-f399-4116-a38e-12573aba58ae'
      @set.game_version = '0.9.1'
      @set.version  = '1.0.0'
      
      parse_args(argv)
      check_args
      mk_set_folders
      parse_set
      write_files

      puts "Set '#{@set.name}' created\n"
      puts "Founded #{@set.num_cards} cards\n"
      puts "Files stored at #@set_dir"
    end
    
    def parse_args(argv)
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
    -v <#.#.#>    Define a version for this set. Defaults to #{@set.game_version}
EOF
      unless argv.empty?
        while arg = argv.shift
          case arg
            when /\A--gameid\z/, /\A-gi\z/
              @set.game_id = argv.shift
            when /\A--gameversion\z/, /\A-gv\z/
              @set.game_version = argv.shift
            when /\A--setname\z/, /\A-n\z/
              @set.name = argv.shift
            when /\A--setversion\z/, /\A-v\z/
              @set.version = argv.shift
            when /\A--version\z/
              print_and_exit "Dvolatooc #{VERSION}"
            when /\A--help\z/, /\A--./
              print_and_exit usage
            else
              @filename = arg if @filename.nil?
          end
        end
      else
        print_and_exit usage
      end
    end
    
    def check_args
      if @filename.nil?
        print_and_exit "Input file required"
      elsif !File.exist?(@filename)
        print_and_exit "File #@filename was not found"
      end
      
      @file = File.new(@filename)
      # Gets first card on the set (cards starts at the 2nd line)
      2.times{@file.gets}
      row = $_.split "\t"
      @set.num_cards = @file.readlines.length+1
      @file.rewind
      
      if row.length < 8
        print_and_exit "Input file is not a valid Lackey deck set"
      end
      
      # Gets the real set name from the input set definition
      @set.real_name = row[1]      
      
      if @set.name.nil? || @set.name.empty?
        @set.name = @set.real_name
      end
      
      # Gets the set code from the set name, as an acronym
      @set.code = ''
      words = @set.real_name.upcase.split(/_| /)
      skip_words = %w(THE AND AN A OF TO IS DECK EL LA LOS LAS DE Y)
      words.map { |w|
        next if skip_words.include? w
        @set.code += w[0,1]
        break if @set.code.length >= 4
      }
      
      # Code too short
      if words[-1].length > 1
        i = 1
        while @set.code.length < 3
          letter = words[-1][i,1]
          break if letter.nil?
          @set.code += letter
          i += 1
        end
      end
    end
    
    def mk_set_folders
      # Folder structure of the OCTGN set
      @set_dir = @set.code+'-v'+@set.version
      Dir.mkdir(@set_dir) unless FileTest.directory?(@set_dir)
      Dir.chdir(@set_dir)
      Dir.mkdir('_rels') unless FileTest.directory?('_rels')
      Dir.mkdir('cards') unless FileTest.directory?('cards')
    end
    
    def parse_set
      @xml_set = ''  # Objects to save the xml string
      @xml_res = ''
      i = 1
      style = Style.new(DIR::STYLE+'style')
      
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
        :name        => @set.name,
        :id          => UUIDTools::UUID.parse_raw(@set.real_name),
        :gameId      => @set.game_id,
        :gameVersion => @set.game_version,
        :version     => @set.version
      ) {
        # Add <cards> child node
        xml.cards {
          # Read each line of the txt file input
          @file.each_with_index do |line, index|
            next if index == 0  # Skip 1st line since are columns names
            card = Card.new(line, i, @set)
            next unless cards[card.name].nil?  # Skip duplicated cards
            cards[card.name] = card
            
            xml.card(
              # <card> attributes
              :name => card.name,
              :id   => card.id
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

            style.render(card, @set)
            
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
        cards.each { |k,card|
          # Add <Relationship> child node
          xml.Relationship(
            # <Relationship> attributes
            :Target => '/cards/' + sprintf("%03d", i) + '.jpg',
            :Id     => 'C' + card.id.hexdigest,
            :Type   => 'http://schemas.octgn.org/picture'
          )
          i += 1
        }  # cards.each
      }  # xml.Relationships
    end
    
    def write_files
      # Write the XML set definition
      file = File.new( @set.code+".xml", "w:UTF-8" )
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
  <Relationship Target='/#{@set.code}.xml' Id='def' Type='http://schemas.octgn.org/set/definition' />
</Relationships>
EOF
      file.close
      
      # Write resources XML file
      file = File.new( "_rels/#{@set.code}.xml.rels", "w" )
      file.puts( @xml_res )
      file.close
    end
    
    def print_and_exit(msg)
      puts msg
      exit 0
    end
    
  end  # class << self
end  # module Dvolatooc

if File.basename(__FILE__) == File.basename($0)
  Dvolatooc.init(ARGV)
end