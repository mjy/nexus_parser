module NexusParser::Tokens

  ENDBLKSTR = '(end|endblock)'.freeze

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
    @regexp = Regexp.new(/\A\s*([\s]*#{ENDBLKSTR}[\s]*;[\s]*)/i)
  end

  # label
  class AuthorsBlk < Token
    @regexp = Regexp.new(/\A\s*(Authors;.*?#{ENDBLKSTR};)\s*/im)
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

  # TODO: Handled, but ignored
  class RespectCase < Token
    @regexp = Regexp.new(/\A\s*(respectcase)\s*/i)
  end

  # label
  class Taxlabels < Token
    @regexp = Regexp.new(/\A\s*(\s*taxlabels\s*)\s*/i)
  end

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

  class LinkLine < Token
    @regexp = Regexp.new(/\A\s*(link.*\s*;)\s*\n*/i)
  end

  # note we grab EOL and ; here
  class ValuePair < Token
    @regexp = Regexp.new(/\A\s*([\w]+\s*=\s*((\'[^\']+\')|(\(.*\))|(\"[^\"]+\")|([^\s;]+)))[\s;]+/i) #  returns key => value hash for tokens like 'foo=bar' or foo = 'b a ar'
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
      # We ignore commas outside (and inside) of groupings, it's fine.
      str.gsub!(/[\, \t]/, '')

      groupers = ['(', ')', '{', '}']
      openers = ['(', '{']
      closers = [')', '}']
      closer_for = { '(' => ')', '{' => '}' }

      a = []
      group = nil
      group_closer = nil
      str.each_char { |c|
        if groupers.include? c
          if ((openers.include?(c) && !group.nil?) ||
            (closers.include?(c) && (group.nil? || c != group_closer)))
            raise(NexusParser::ParseError,
              "Mismatched grouping in matrix row '#{str}'")
          end

          if openers.include? c
            group = []
            group_closer = closer_for[c]
          else # c is a closer
            if group.count == 1
              a << group.first
            elsif group.count > 1
              a << group
            end
            group = nil
            group_closer = nil
          end
        else
          if group.nil?
            a << c
          else
            group << c
          end
        end
      }

      raise(NexusParser::ParseError,
        "Unclosed grouping in matrix row '#{str}'") if !group.nil?

      @value = a
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
    @regexp = Regexp.new(/\A\s*(trees;.*?#{ENDBLKSTR};)\s*/im) # note the multi-line /m
  end

  class SetsBlk < Token
    @regexp = Regexp.new(/\A\s*(sets;.*?#{ENDBLKSTR};)\s*/im)
  end

  class MqCharModelsBlk < Token
    @regexp = Regexp.new(/\A\s*(MESQUITECHARMODELS;.*?#{ENDBLKSTR};)\s*/im)
  end

  class LabelsBlk < Token
    @regexp = Regexp.new(/\A\s*(LABELS;.*?#{ENDBLKSTR};)\s*/im)
  end

  class AssumptionsBlk < Token
    @regexp = Regexp.new(/\A\s*(ASSUMPTIONS;.*?#{ENDBLKSTR};)\s*/im)
  end

  class CodonsBlk < Token
    @regexp = Regexp.new(/\A\s*(CODONS;.*?#{ENDBLKSTR};)\s*/im)
  end

  class MesquiteBlk < Token
    @regexp = Regexp.new(/\A\s*(Mesquite;.*?#{ENDBLKSTR};)\s*/im)
  end

  class BlkEnd < Token
    @regexp = Regexp.new(/\A[\s]*(#{ENDBLKSTR};)\s*/i)
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

  # NexusParser::Tokens::NexusComment

  # this list also defines priority, i.e. if tokens have overlap (which they shouldn't!!) then the earlier indexed token will match first
  def self.nexus_file_token_list
    [ NexusParser::Tokens::NexusStart,
      NexusParser::Tokens::BeginBlk,
      NexusParser::Tokens::EndBlk,
      NexusParser::Tokens::AuthorsBlk,
      NexusParser::Tokens::SetsBlk,
      NexusParser::Tokens::MqCharModelsBlk,
      NexusParser::Tokens::AssumptionsBlk,
      NexusParser::Tokens::CodonsBlk,
      NexusParser::Tokens::MesquiteBlk,
      NexusParser::Tokens::TreesBlk,
      NexusParser::Tokens::LabelsBlk,
      NexusParser::Tokens::TaxaBlk,
      NexusParser::Tokens::NotesBlk,
      NexusParser::Tokens::Title,
      NexusParser::Tokens::Taxlabels,
      NexusParser::Tokens::Dimensions,
      NexusParser::Tokens::FileLbl,
      NexusParser::Tokens::Format,
      NexusParser::Tokens::RespectCase,
      NexusParser::Tokens::Equals,
      NexusParser::Tokens::ValuePair,  # this has bad overlap with Label
      NexusParser::Tokens::CharStateLabels,
      NexusParser::Tokens::ChrsBlk,
      NexusParser::Tokens::Number, # partial overlap with Label
      NexusParser::Tokens::Matrix,
      NexusParser::Tokens::SemiColon,
      NexusParser::Tokens::MesquiteIDs,
      NexusParser::Tokens::MesquiteBlockID,
      NexusParser::Tokens::BlkEnd,
      NexusParser::Tokens::Colon,
      NexusParser::Tokens::BckSlash,
      NexusParser::Tokens::Comma,
      NexusParser::Tokens::LParen,
      NexusParser::Tokens::RParen,
      NexusParser::Tokens::LBracket,
      NexusParser::Tokens::RBracket,
      NexusParser::Tokens::Label, # must be before RowVec
      NexusParser::Tokens::RowVec,
      NexusParser::Tokens::LinkLine,
    ]
  end

end

