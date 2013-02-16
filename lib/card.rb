module Dvolatooc
  class Card

    attr_reader :name, :supertype, :type, :subtype, :value, :rules, :flavor, :artist, :number, :creator, :id
    
    def initialize(raw, number, set)
      # Lackey columns:
      # 0:Name  1:Set  2:ImageFile  3:Type  4:CornerValue  5:Text  6:FlavorText  7:Creator
      raw = raw.split "\t"  # Split by tab char
      type = raw[3].split /\s\-|\+\s/

      @setinfo = set
      
      @name = raw[0].strip
      @type = type[0].strip
      @subtype = type.length > 1 ? type[1..-1].join(' - ') : ''
      @supertype = @type + (@subtype.empty? ? '' : ' - '+@subtype)
      @value = raw[4].strip
      @rules = raw[5].strip
      @flavor = raw[6].nil? ? '' : raw[6].strip
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