module NexusFile::Tokens

  class Token 
    # this allows access the the class attribute regexp, without using a class variable
    class << self; attr_reader :regexp; end
    attr_reader :value    
    def initialize(str)
      @value = str
    end
  end

  # in ruby, \A is needed if you want to only match at the beginning of the string, we need this everywhere, as we're
  # moving along popping off
 
  class NexusStart < Token
    @regexp = Regexp.new(/\A.*(\#nexus)\s*/i)
  end

  # at present we strip comments pre-parser initialization, because they can be placed anywhere it gets tricky to parse otherwise, and besides, they are non-standard
  # class NexusComment < Token
  #   @regexp = Regexp.new(/\A\s*(\[[^\]]*\])\s*/i)
  #   def initialize(str)
  #     str = str[1..-2] # strip the []
  #     str.strip!   
  #    @value = str
  #  end
  # end

  class BeginBlk < Token
    @regexp = Regexp.new(/\A\s*(\s*Begin\s*)/i)
  end

  class EndBlk < Token
    @regexp = Regexp.new(/\A\s*([\s\n]*End[\s\n]*;[\s\n]*)/i)
  end

  # label 
  class AuthorsBlk < Token
    @regexp = Regexp.new(/\A\s*(Authors;.*?END;)\s*/im) 
  end

  # label 
  class TaxaBlk < Token
    @regexp = Regexp.new(/\A\s*(\s*Taxa\s*;)\s*/i)
  end

  # label 
  class NotesBlk < Token
    @regexp = Regexp.new(/\A\s*(\s*Notes\s*;)\s*/i)
  end

  class FileLbl < Token
    @regexp = Regexp.new(/\A\s*(\s*File\s*)\s*/i)
  end

  # label and content
  class Title < Token
    @regexp = Regexp.new(/\A\s*(title[^\;]*;)\s*/i)
  end

  class Dimensions < Token
    @regexp = Regexp.new(/\A\s*(DIMENSIONS)\s*/i)
  end

  class Format < Token
    @regexp = Regexp.new(/\A\s*(format)\s*/i)
  end

  # label 
  class Taxlabels < Token
     @regexp = Regexp.new(/\A\s*(\s*taxlabels\s*)\s*/i)
  end

  # same as ID
  class Label < Token
    @regexp = Regexp.new('\A\s*((\'+[^\']+\'+)|(\"+[^\"]+\"+)|(\w[^,:(); \t\n]*|_)+)\s*') #  matches "foo and stuff", foo, 'stuff or foo', '''foo''', """bar""" BUT NOT ""foo" " # choking on 'Foo_stuff_things'
    def initialize(str)
      str.strip!
      str = str[1..-2] if str[0..0] == "'" # get rid of quote marks
      str = str[1..-2] if str[0..0] == '"' 
      str.strip! 
      @value = str
    end
  end

  class ChrsBlk < Token
    @regexp = Regexp.new(/\A\s*(characters\s*;)\s*/i)
  end

  # note we grab EOL and ; here 
  class ValuePair < Token
    @regexp = Regexp.new(/\A\s*([\w\d\_\&]+\s*=\s*((\'[^\']+\')|(\(.*\))|(\"[^\"]+\")|([^\s\n\t;]+)))[\s\n\t;]+/i) #  returns key => value hash for tokens like 'foo=bar' or foo = 'b a ar'
    def initialize(str)
      str.strip!
      str = str.split(/=/)
      str[1].strip!
      str[1] = str[1][1..-2] if str[1][0..0] == "'" 
      str[1] = str[1][1..-2] if str[1][0..0] ==  "\"" 
      @value = {str[0].strip.downcase.to_sym => str[1].strip}
    end
  end

  class Matrix < Token
    @regexp = Regexp.new(/\A\s*(matrix)\s*/i)
  end

  class RowVec < Token
    @regexp = Regexp.new(/\A\s*(.+)\s*\n/i)
     def initialize(str)
       # meh! Ruby is simpler to read than Perl?
       # handles both () and {} style multistates
       s = str.split(/\(|\)|\}|\{/).collect{|s| s=~ /[\,|\s]/ ? s.split(/[\,|\s]/) : s}.inject([]){|sum, x| x.class == Array ? sum << x.delete_if {|y| y == "" } : sum + x.strip.split(//)}
      @value = s
    end
  end

  class CharStateLabels < Token
    @regexp = Regexp.new(/\A\s*(CHARSTATELABELS)\s*/i)
  end

  class MesquiteIDs < Token
    @regexp = Regexp.new(/\A\s*(IDS[^;]*;)\s*/i)
  end

  class MesquiteBlockID < Token
    @regexp = Regexp.new(/\A\s*(BLOCKID[^;]*;)\s*/i)
  end

  # unparsed blocks
  
  class TreesBlk < Token
    @regexp = Regexp.new(/\A\s*(trees;.*?END;)\s*/im) # note the multi-line /m
  end

  class SetsBlk < Token
    @regexp = Regexp.new(/\A\s*(sets;.*?END;)\s*/im) 
  end

  class MqCharModelsBlk < Token
    @regexp = Regexp.new(/\A\s*(MESQUITECHARMODELS;.*?END;)\s*/im) 
  end

  class LabelsBlk < Token
    @regexp = Regexp.new(/\A\s*(LABELS;.*?END;)\s*/im) 
  end

  class AssumptionsBlk < Token
    @regexp = Regexp.new(/\A\s*(ASSUMPTIONS;.*?END;)\s*/im) 
  end

  class CodonsBlk < Token
    @regexp = Regexp.new(/\A\s*(CODONS;.*?END;)\s*/im) 
  end

  class MesquiteBlk < Token
    @regexp = Regexp.new(/\A\s*(Mesquite;.*?END;)\s*/im) 
  end

  class BlkEnd < Token
    @regexp = Regexp.new(/\A[\s\n]*(END;)\s*/i)
  end

  class LBracket < Token
    @regexp = Regexp.new('\A\s*(\[)\s*')
  end

  class RBracket < Token
    @regexp = Regexp.new('\A\s*(\])\s*')
  end

  class LParen < Token
      @regexp = Regexp.new('\A\s*(\()\s*')
  end

  class RParen < Token
    @regexp = Regexp.new('\A\s*(\))\s*')
  end
 
  class Equals < Token
    @regexp = Regexp.new('\A\s*(=)\s*')
  end

  class BckSlash < Token
    @regexp = Regexp.new('\A\s*(\/)\s*')
  end

  # labels
  class ID < Token
    @regexp = Regexp.new('\A\s*((\'[^\']+\')|(\w[^,:(); \t\n]*|_)+)\s*')
    def initialize(str)
      str.strip! 
      str = str[1..-2] if str[0..0] == "'" # get rid of quote marks
      @value = str
    end
  end

  class Colon < Token
    @regexp = Regexp.new('\A\s*(:)\s*')
  end

  class SemiColon < Token
    @regexp = Regexp.new('\A\s*(;)\s*')
  end

  class Comma < Token
    @regexp = Regexp.new('\A\s*(\,)\s*')
  end

  class Number < Token
    @regexp = Regexp.new('\A\s*(-?\d+(\.\d+)?([eE][+-]?\d+)?)\s*')
    def initialize(str)
      # a little oddness here, in some case we don't want to include the .0
      # see issues with numbers as labels
      if str =~ /\./
        @value = str.to_f
      else
        @value = str.to_i
      end

    end
  end

  # NexusFile::Tokens::NexusComment

  # this list also defines priority, i.e. if tokens have overlap (which they shouldn't!!) then the earlier indexed token will match first
  def self.nexus_file_token_list
    [ NexusFile::Tokens::NexusStart,
      NexusFile::Tokens::BeginBlk,
      NexusFile::Tokens::EndBlk,
      NexusFile::Tokens::AuthorsBlk,
      NexusFile::Tokens::SetsBlk,
      NexusFile::Tokens::MqCharModelsBlk,
      NexusFile::Tokens::AssumptionsBlk,
      NexusFile::Tokens::CodonsBlk,
      NexusFile::Tokens::MesquiteBlk,
      NexusFile::Tokens::TreesBlk,
      NexusFile::Tokens::LabelsBlk,
      NexusFile::Tokens::TaxaBlk,
      NexusFile::Tokens::NotesBlk,
      NexusFile::Tokens::Title, 
      NexusFile::Tokens::Taxlabels,
      NexusFile::Tokens::Dimensions,
      NexusFile::Tokens::FileLbl,
      NexusFile::Tokens::Format,
      NexusFile::Tokens::Equals,
      NexusFile::Tokens::ValuePair,  # this has bad overlap with Label and likely IDs (need to kill the latter, its a lesser Label)
      NexusFile::Tokens::CharStateLabels,
      NexusFile::Tokens::ChrsBlk,
      NexusFile::Tokens::Number,
      NexusFile::Tokens::Matrix,
      NexusFile::Tokens::SemiColon,
      NexusFile::Tokens::MesquiteIDs,
      NexusFile::Tokens::MesquiteBlockID,
      NexusFile::Tokens::BlkEnd,
      NexusFile::Tokens::Colon,
      NexusFile::Tokens::BckSlash,
      NexusFile::Tokens::Comma,
      NexusFile::Tokens::LParen,
      NexusFile::Tokens::RParen,
      NexusFile::Tokens::LBracket,
      NexusFile::Tokens::RBracket,
      NexusFile::Tokens::Label, # must be before RowVec 
      NexusFile::Tokens::RowVec,
      NexusFile::Tokens::ID # need to trash this
    ]   
  end
  
end

