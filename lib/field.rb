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

require 'rubygems'
require 'RMagick'

module Dvolatooc

  class Field < Hash
    
    GRAVITY_NAMES = {
      :topleft       => Magick::NorthWestGravity,
      :topcenter     => Magick::NorthGravity,
      :topright      => Magick::NorthEastGravity,
      :centerleft    => Magick::WestGravity,
      :centercenter  => Magick::CenterGravity,
      :centerright   => Magick::EastGravity,
      :bottomleft    => Magick::SouthWestGravity,
      :bottomcenter  => Magick::SouthGravity,
      :bottomright   => Magick::SouthEastGravity
    }
    
    WEIGHT_TYPE = {
      :light    => Magick::LighterWeight,
      :normal   => Magick::NormalWeight,
      :bold     => Magick::BoldWeight,
      :bolder   => Magick::BolderWeight
    }
    
    STYLE_TYPE = {
      :normal   => Magick::NormalStyle,
      :italic   => Magick::ItalicStyle,
      :oblique  => Magick::ObliqueStyle
    }

    def initialize(hash, card)
      self.merge!(hash)
      @card = card
    end

    def text_color
      filter(self['text-color'])
    end

    def vertical_align
      self['vertical-align'] ? self['vertical-align'] : 'top'
    end

    def text_align
      self['text-align'] ? self['text-align'] : 'left'
    end

    def align
      a = vertical_align + text_align
      GRAVITY_NAMES[a.to_sym]
    end

    def font_weight
      v = self['font-weight']
      return Magick::AnyWeight unless v
      return WEIGHT_TYPE[v.to_sym] if v.is_a? String
      v
    end

    def font_style
      self['font-style'] ? STYLE_TYPE[self['font-style'] .to_sym] : Magick::AnyStyle
    end
    
    def background_color
      self['background-color'] ? filter(self['background-color']) : 'white'
    end

    def filter(v=nil)
      v = self if v.nil?

      if v.is_a?(Hash)
        if v[@card.name]
          v = v[@card.name]
        elsif v[@card.subtype]
          v = v[@card.subtype]
        elsif v[@card.type]
          v = v[@card.type]
        elsif v['default']
          v = v['default']
        end
      end
      v
    end
  end  # class FIeld
  
end  # module Dvolatooc