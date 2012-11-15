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
require 'tempfile'

class String
  def is_number?
    true if Float(self) rescue false
  end
end

module Dvolatooc

  class Style

    FIELDS = %w(card templates name value supertype rules flavor copyright artist number picture draw)
    IMG_FORMAT = %w(.jpg .jpeg .gif .png)

    def initialize(dir=nil, pics=nil)
      @fields = {}
      @pics = DIR::BASE+pics + '/' unless pics.nil? || !File.exist?(DIR::BASE+pics)
      
      unless dir.nil?
        @dir = DIR::BASE+dir + '/'
        parse(@dir+'style')
      else
        tf = Tempfile.new('Dvolatooc_def_style')
        tf.puts DEF_STYLE
        tf.close
        parse(tf.path)
        tf.unlink
      end

      @draw = Magick::Draw.new
      @cols = {}
    end

    def parse(filename)
      @file = File.new(filename)
      @file.each do |line|
        arr = line_to_array(line)
        unless arr.empty?
          if arr.length == 1 && FIELDS.include?(arr[0])
            @fields[arr[0]] = get_props(1)
          end
        end
      end
    end  # def parse

    def get_props(t)
      props = {}

      @file.each do |line|
        m = line.match(/^\t+/)
        tabs = m.nil? ? 0 : m[0].count("\t")
        if tabs < t && line =~ /\S/
          # Seek to the start of the line. -1 is for \n at the end
          @file.seek(-line.bytesize-1, File::SEEK_CUR)
          break
        end

        arr = line_to_array(line)
        unless arr.empty?
          if arr.length == 1
            props[arr[0]] = get_props(t+1)
          else
            props[arr[0]] = parse_prop(arr[0], arr[1])
          end
        end
      end

      props
    end  # def getProps

    def line_to_array(line)
      line = line.partition('//').shift
      line.split(':').map { |e| e =~ /^\s*$/ ? nil : e.strip }.compact
    end

    def parse_prop(key, value)
        value = value.to_f if value.is_number?
        value
    end

    def field(name)
      Field.new(@fields[name], @card)
    end

    def render(card, set)
      @card = card
      @attrs = field('card')
      
      unless @fields['templates'].nil?
        tpl = field('templates').filter
        @image = Magick::ImageList.new(@dir+tpl)
      else
        @image = Magick::Image.new(@attrs['width'], @attrs['height']) { self.background_color = 'white' }
      end
      
      draw_border() unless @attrs.border_color.nil?
      draw_extra(field('draw')) if @fields['draw']

      draw_text(card.name, 'name')
      draw_text(card.value, 'value')
      draw_text(card.supertype, 'supertype')
      draw_text(card.rules, 'rules')
      draw_text(card.flavor, 'flavor')
      draw_text(card.creator, 'copyright')
      draw_text(card.artist, 'artist')
      draw_text([set.code, card.number, set.num_cards], 'number')
      draw_pic('picture') if @pics

      @image.write('cards/'+sprintf("%03d", card.number)+'.jpg')
    end

    def draw_border
      @img_cache = {} if @img_cache.nil?

      if @img_cache[@attrs.border_color].nil?
        tmp = Magick::Image.new(@attrs['width'], @attrs['height'])
        width = @attrs['border-width'].nil? ? 8 : @attrs['border-width']
        width_2 = width / 2.0
        radius = @attrs['border-radius'].nil? ? 8 : @attrs['border-radius']
        @draw.stroke(@attrs.border_color)
        @draw.stroke_width(width)
        @draw.fill(@attrs.background_color)
        @draw.roundrectangle(width_2,width_2, @attrs['width']-width_2, @attrs['height']-width_2, radius, radius)
        @draw.draw(tmp)
        @img_cache[@attrs.border_color] = tmp
      end

      @image.composite!(@img_cache[@attrs.border_color], 0, 0, Magick::OverCompositeOp)
    end

    def draw_extra(d)      
      @img_cache = {} if @img_cache.nil?

      d.each_key { |k|
        cmd = d.filter(d[k])
        if @img_cache[cmd].nil?
          arr = cmd.match(/(\w+)\((.+)\)/)
          if arr.length == 3
            if arr[1] == 'stroke'
              tmp = Magick::Image.new(@attrs['width'], @attrs['height'])
              params = arr[2].split(',')
              @draw.stroke(params[0])
              @draw.stroke_width(params[1].to_f)
              @draw.line(params[2].to_f, params[3].to_f, params[4].to_f, params[5].to_f)
              @draw.draw(tmp)
              @img_cache[cmd] = tmp
            end
          end
        end

        @image.composite!(@img_cache[cmd], 0, 0, Magick::OverCompositeOp) unless @img_cache[cmd].nil?
      }
    end

    def draw_text(str, field)
      return if str.empty?

      f = field(field)

      @draw.font = @dir + f['font'] unless f['font'].nil?
      @draw.font_family = f['font-family'] unless f['font-family'].nil?
      @draw.font_weight = f.font_weight
      @draw.font_style  = f.font_style
      @draw.pointsize = f['font-size']
      @draw.fill = f.text_color
      @draw.gravity = f.align

      x = f['x']
      y = f['y']

      y = -y if f.vertical_align == 'bottom'
      x = -x if f.text_align == 'right'

      unless f['format'].nil?
        format = f['format'].gsub(/(^")|("$)/, '')
        if str.is_a?(Array)
          str = sprintf(format, *str)
        else
          str = sprintf(format, str)
        end
      end

      unless f['multiline'].nil?
        if @cols[field].nil?
          metrics = @draw.get_type_metrics(@image, 'n')
          @cols[field] = (f['width'] / metrics.width).floor + 4
        end
        str = text_multiline(str, @cols[field])
      end

      unless f['stretch'].nil?
        metrics = @draw.get_type_metrics(@image, str)
        if metrics.width > f['width']
          @draw.pointsize = f['font-size']*f['width'] / metrics.width
        end
      end

      unless f['combined'].nil? || !FIELDS.include?(f['combined'])
        other = @card.send(f['combined'])
        unless other.empty?
          metrics = @draw.get_multiline_type_metrics(@image, other)
          y += metrics.height + 20
        end
      end

      #              draw, width, height, x, y, text
      @image.annotate(@draw, f['width'], f['height'], x, y, str)
    end

    def draw_pic(field)
      f = field(field)
      file = nil

      IMG_FORMAT.each{ |ext|
        file1 = @pics + @card.number.to_s + ext
        file2 = @pics + @card.name + ext
        if FileTest.file?(file1)
          file = file1
          break
        elsif FileTest.file?(file2)
          file = file2
        end
      }

      unless file.nil?
        pict = Magick::ImageList.new(file)
        pict.resize_to_fill!(f['width'], f['height'])
        @image.composite!(pict, f['x'], f['y'], Magick::OverCompositeOp)
      end
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

      m.join '\n'
    end
    
  end  # class Style

end  # module Dvolatooc