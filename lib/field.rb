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

    def x;  get_value('x', 0);  end
    def y;  get_value('y', 0);  end
    def width;  get_value('width');  end
    def height; get_value('height'); end

    def font; get_value('font'); end
    def font_family; get_value('font-family'); end
    def font_size; get_value('font-size', 18); end

    def font_weight
      v = get_value('font-weight')
      return Magick::AnyWeight unless v
      return WEIGHT_TYPE[v.to_sym] if v.is_a? String
      v
    end

    def font_style
      v = get_value('font-style')
      v ? STYLE_TYPE[v.to_sym] : Magick::AnyStyle
    end

    def text_color; get_value('text-color'); end
    def background_color; get_value('background-color', 'white'); end

    def format
      v = get_value('format')
      v.gsub!(/(^")|("$)/, '') if v
      v
    end

    def vertical_align; get_value('vertical-align', 'top'); end
    def text_align; get_value('text-align', 'left'); end

    def align
      a = vertical_align + text_align
      GRAVITY_NAMES[a.to_sym]
    end

    def multiline; get_value('multiline') === 'true'; end
    def stretch; get_value('stretch') === 'true'; end
    def combined; get_value('combined'); end    
    
    def border_color; get_value('border-color'); end
    def border_width; get_value('border-width', 8); end
    def border_radius; get_value('border-radius', 8); end

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

    private
    def get_value(name, v=nil)
      self[name] ? filter(self[name]) : v
    end
  end  # class FIeld
  
end  # module Dvolatooc