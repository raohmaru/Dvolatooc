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

module Dvolatooc
  class Card

    attr_reader :name, :supertype, :type, :subtype, :rarity, :value, :rules, :flavor, :artist, :number, :creator, :id
    
    def initialize(raw, number, set)
      # Lackey columns:
      # 0:Name  1:Set  2:ImageFile  3:Type  4:CornerValue  5:Text  6:FlavorText  7:Creator
      raw = raw.split "\t"  # Split by tab char
      type = raw[3].split /\s\-\s/

      @setinfo = set
      
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
      @id = UUIDTools::UUID.parse_raw( @setinfo.real_name+@name )
    end

    def thing?
      /thing|objeto/i.match(@type) != nil
    end
    
    def action?
      /action|acción/i.match(@type) != nil
    end
    
  end  # class Card
end  # module Dvolatooc