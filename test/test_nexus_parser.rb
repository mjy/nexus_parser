require 'test/unit'
require 'rubygems'
require 'byebug'

require File.expand_path(File.join(File.dirname(__FILE__), '../lib/nexus_parser'))

class NexusParserTest < Test::Unit::TestCase
  def test_truth
    assert true
  end
end

class Test_NexusParser_Builder < Test::Unit::TestCase
  def test_builder
    b = NexusParser::Builder.new
    assert foo = b.nexus_file
    assert_equal [], foo.taxa
    assert_equal [], foo.characters
    assert_equal [], foo.codings
    assert_equal [], foo.sets
  end
end


class Test_Regex < Test::Unit::TestCase
  def test_begin_taxa
    txt = "  aslkfja\n Begin taxa; BLorf   end; "
    @regexp = Regexp.new(/\s*(Begin\s*taxa\s*;)\s*/i)
    assert txt =~ @regexp
  end
end


class Test_Lexer < Test::Unit::TestCase
  def test_lexer
    lexer = NexusParser::Lexer.new("[ foo ] BEGIN taxa; BLORF end;")
    assert lexer.pop(NexusParser::Tokens::LBracket)
    assert id = lexer.pop(NexusParser::Tokens::Label)
    assert_equal(id.value, "foo")
    assert lexer.pop(NexusParser::Tokens::RBracket)
    assert lexer.pop(NexusParser::Tokens::BeginBlk)
    assert lexer.pop(NexusParser::Tokens::TaxaBlk)
    assert foo = lexer.pop(NexusParser::Tokens::Label)
    assert_equal("BLORF", foo.value) # truncating whitespace
    assert lexer.pop(NexusParser::Tokens::BlkEnd)

    lexer2 = NexusParser::Lexer.new("[ foo ] begin authors; BLORF end; [] ()  some crud here")
    assert lexer2.pop(NexusParser::Tokens::LBracket)
    assert id = lexer2.pop(NexusParser::Tokens::Label)
    assert_equal(id.value, "foo")
    assert lexer2.pop(NexusParser::Tokens::RBracket)
    assert lexer2.pop(NexusParser::Tokens::BeginBlk)
    assert lexer2.pop(NexusParser::Tokens::AuthorsBlk)
    assert lexer2.pop(NexusParser::Tokens::LBracket)
    assert lexer2.pop(NexusParser::Tokens::RBracket)
    assert lexer2.pop(NexusParser::Tokens::LParen)
    assert lexer2.pop(NexusParser::Tokens::RParen)

    lexer2a = NexusParser::Lexer.new("begin authors; BLORF endblock; []")
    assert lexer2a.pop(NexusParser::Tokens::BeginBlk)
    assert lexer2a.pop(NexusParser::Tokens::AuthorsBlk)
    assert lexer2a.pop(NexusParser::Tokens::LBracket)
    assert lexer2a.pop(NexusParser::Tokens::RBracket)

    lexer3 = NexusParser::Lexer.new("[ foo ] Begin Characters; BLORF end; [] ()  some crud here")
    assert lexer3.pop(NexusParser::Tokens::LBracket)
    assert id = lexer3.pop(NexusParser::Tokens::Label)
    assert_equal(id.value, "foo")
    assert lexer3.pop(NexusParser::Tokens::RBracket)
    assert lexer3.pop(NexusParser::Tokens::BeginBlk)
    assert lexer3.pop(NexusParser::Tokens::ChrsBlk)
    assert foo = lexer3.pop(NexusParser::Tokens::Label)
    assert_equal("BLORF", foo.value)
    assert lexer3.pop(NexusParser::Tokens::BlkEnd)

    lexer4 = NexusParser::Lexer.new("Begin Characters; 123123123 end; [] ()  some crud here")
    assert lexer4.pop(NexusParser::Tokens::BeginBlk)
    assert lexer4.pop(NexusParser::Tokens::ChrsBlk)
    assert foo = lexer4.pop(NexusParser::Tokens::Number)
    assert_equal(123123123, foo.value)
    assert lexer4.pop(NexusParser::Tokens::BlkEnd)

    lexer5 = NexusParser::Lexer.new("(0,1)")
    assert lexer5.pop(NexusParser::Tokens::LParen)
    assert foo = lexer5.pop(NexusParser::Tokens::Number)
    assert_equal(0, foo.value)
    assert lexer5.pop(NexusParser::Tokens::Comma)
    assert foo = lexer5.pop(NexusParser::Tokens::Number)
    assert_equal(1, foo.value)
    assert lexer5.pop(NexusParser::Tokens::RParen)

    lexer6 =  NexusParser::Lexer.new(" 210(0,1)10A1\n")
    assert foo = lexer6.pop(NexusParser::Tokens::RowVec)
    assert_equal(["2","1","0",["0","1"],"1","0","A","1"], foo.value)

    lexer6a =  NexusParser::Lexer.new("  21a(0 1)0b{345}(0)(1 a)\n")
    assert foo = lexer6a.pop(NexusParser::Tokens::RowVec)
    assert_equal(["2", "1", "a", ["0", "1"], "0", "b", ["3", "4", "5"], "0", ["1", "a"]], foo.value)

    lexer6b =  NexusParser::Lexer.new(" 201(01){0 1}0100\x0A") # *nix line ending
    assert foo = lexer6b.pop(NexusParser::Tokens::RowVec)
    assert_equal(["2", "0", "1", ["0", "1"], ["0", "1"], "0", "1", "0", "0"], foo.value)

    lexer6c =  NexusParser::Lexer.new(" 201{0 1}{01}0100\x0D\x0A") # * dos line ending
    assert foo = lexer6c.pop(NexusParser::Tokens::RowVec)
    assert_equal(["2", "0", "1", ["0", "1"], ["0", "1"], "0", "1", "0", "0"], foo.value)


    lexer7 = NexusParser::Lexer.new("read nothing till Nexus, not that nexus 13243 Block [] ();, this one: #nexus FOO")
    assert foo = lexer7.pop(NexusParser::Tokens::NexusStart)
    assert_equal('#nexus', foo.value)


    ## we strip comments before parsing now
    # lexer8 = NexusParser::Lexer.new("[ foo ] Begin Characters; BLORF end; [] ()  some crud here")
    # assert foo = lexer8.pop(NexusParser::Tokens::NexusComment)
    # assert_equal "foo", foo.value

    # assert lexer.pop(NexusParser::Tokens::Colon)
    # assert num = lexer.pop(NexusParser::Tokens::Number)
    # assert_equal(num.value, 0.0)
    # assert lexer.pop(NexusParser::Tokens::Comma)
    # assert lexer.pop(NexusParser::Tokens::SemiColon)
  end

  def test_row_vec
    lexer = NexusParser::Lexer.new("0?(0 1)10(A BD , C)1(0,1,2)1-\n")
    assert foo = lexer.pop(NexusParser::Tokens::RowVec)
    assert_equal(["0", "?", ["0", "1"], "1", "0", ["A", "B", "D", "C"], "1", ["0", "1", "2"], "1", "-"], foo.value)
  end

  def test_ungrouped_spaces_in_row_vec
    lexer = NexusParser::Lexer.new("- A 12(BC) ? \n")
    assert foo = lexer.pop(NexusParser::Tokens::RowVec)
    assert_equal(['-', 'A', '1', '2', ['B', 'C'], '?'], foo.value)
  end

  def test_mismatched_parens_row_vec
    lexer = NexusParser::Lexer.new("01(12(13\n")
    assert_raise_with_message(NexusParser::ParseError, /Mismatch/) {
      lexer.pop(NexusParser::Tokens::RowVec)
    }
  end

  def test_mismatched_groupers_row_vec
    lexer = NexusParser::Lexer.new("01(12}13\n")
    assert_raise_with_message(NexusParser::ParseError, /Mismatch/) {
      lexer.pop(NexusParser::Tokens::RowVec)
    }
  end

  def test_nested_parens_row_vec
    lexer = NexusParser::Lexer.new("01(12(34))13\n")
    assert_raise_with_message(NexusParser::ParseError, /Mismatch/) {
      lexer.pop(NexusParser::Tokens::RowVec)
    }
  end

  def test_unclosed_parens_row_vec
    lexer = NexusParser::Lexer.new("01(123413\n")
    assert_raise_with_message(NexusParser::ParseError, /Unclosed/) {
      lexer.pop(NexusParser::Tokens::RowVec)
    }
  end

  def test_punctuation
    lexer = NexusParser::Lexer.new(',/=](\'NOT23\'[);,')
    assert lexer.peek(NexusParser::Tokens::Comma)
    assert lexer.pop(NexusParser::Tokens::Comma)
    assert lexer.pop(NexusParser::Tokens::BckSlash)
    assert lexer.pop(NexusParser::Tokens::Equals)
    assert lexer.pop(NexusParser::Tokens::RBracket)
    assert lexer.pop(NexusParser::Tokens::LParen)
    assert foo = lexer.pop(NexusParser::Tokens::Label)
    assert_equal "NOT23", foo.value
    assert lexer.pop(NexusParser::Tokens::LBracket)
    assert lexer.pop(NexusParser::Tokens::RParen)
    assert lexer.pop(NexusParser::Tokens::SemiColon)
    assert lexer.pop(NexusParser::Tokens::Comma)

  end

  def test_tax_labels
    lexer = NexusParser::Lexer.new("Taxlabels 'foo' bar blorf \"stuff things\" stuff 'and foo';")
    assert foo = lexer.pop(NexusParser::Tokens::Taxlabels)
    assert_equal("Taxlabels ", foo.value)
  end

  def test_EndBlk
    lexer = NexusParser::Lexer.new("   \n\n End   ;")
    assert foo = lexer.pop(NexusParser::Tokens::EndBlk)
    lexer = NexusParser::Lexer.new("\n\nEndblock;")
    assert foo = lexer.pop(NexusParser::Tokens::EndBlk)

    lexer = NexusParser::Lexer.new("123123  \n\nEnd;")
    assert !lexer.peek(NexusParser::Tokens::EndBlk)
    lexer = NexusParser::Lexer.new("this is not an \"end\"\n\nEnd;")
    assert !lexer.peek(NexusParser::Tokens::EndBlk)
  end

  def test_semicolon
    lexer = NexusParser::Lexer.new("; Matrix foo")
    assert lexer.peek(NexusParser::Tokens::SemiColon)
    assert foo = lexer.pop(NexusParser::Tokens::SemiColon)
  end

  def test_label
    lexer = NexusParser::Lexer.new(' \'foo\' bar, blorf; "stuff things" stuff \'and foo\' 23434 ""asdf""  \'Foo_And_Stuff\' ')
    assert foo = lexer.pop(NexusParser::Tokens::Label)
    assert_equal "foo", foo.value
    assert foo = lexer.pop(NexusParser::Tokens::Label)
    assert_equal "bar", foo.value
    assert lexer.pop(NexusParser::Tokens::Comma)
    assert foo = lexer.pop(NexusParser::Tokens::Label)
    assert_equal "blorf", foo.value
    assert lexer.pop(NexusParser::Tokens::SemiColon)
    assert foo = lexer.pop(NexusParser::Tokens::Label)
    assert_equal "stuff things", foo.value
    assert foo = lexer.pop(NexusParser::Tokens::Label)
    assert_equal "stuff", foo.value
    assert foo = lexer.pop(NexusParser::Tokens::Label)
    assert_equal "and foo", foo.value
    assert foo = lexer.pop(NexusParser::Tokens::Label)
    assert_equal "23434", foo.value
    assert foo = lexer.pop(NexusParser::Tokens::Label)
    assert_equal '"asdf"', foo.value
    assert foo = lexer.pop(NexusParser::Tokens::Label)
    assert_equal 'Foo_And_Stuff', foo.value
  end

  def test_odd_labels
    lexer = NexusParser::Lexer.new("blorf 'fan shaped, narrow base and broad tip (Selkirkiella, Kochiura)' \"\"\" foo \"\"\"  '''rupununi''' '''tanzania''' '''cup-shaped'''   bar  blorf\n;")
    assert foo = lexer.pop(NexusParser::Tokens::Label)
    assert_equal "blorf", foo.value
    assert foo = lexer.pop(NexusParser::Tokens::Label)
    assert_equal "fan shaped, narrow base and broad tip (Selkirkiella, Kochiura)", foo.value
    assert foo = lexer.pop(NexusParser::Tokens::Label)
    assert_equal '"" foo ""', foo.value
    assert foo = lexer.pop(NexusParser::Tokens::Label)
    assert_equal "''rupununi''", foo.value
    assert foo = lexer.pop(NexusParser::Tokens::Label)
    assert_equal "''tanzania''", foo.value
    assert foo = lexer.pop(NexusParser::Tokens::Label)
    assert_equal "''cup-shaped''", foo.value
    assert foo = lexer.pop(NexusParser::Tokens::Label)
    assert_equal "bar", foo.value
    assert foo = lexer.pop(NexusParser::Tokens::Label)
    assert_equal "blorf", foo.value
    assert foo = lexer.pop(NexusParser::Tokens::SemiColon)
  end

  def test_title
    lexer = NexusParser::Lexer.new( "TITLE 'Scharff&Coddington_1997_Araneidae';")
    assert foo = lexer.pop(NexusParser::Tokens::Title)
    assert_equal  "TITLE 'Scharff&Coddington_1997_Araneidae';", foo.value
  end


  def test_dimensions
    input = " DIMENSIONS  NCHAR= 10"
    lexer = NexusParser::Lexer.new(input)
    assert foo = lexer.pop(NexusParser::Tokens::Dimensions)
    assert_equal  "DIMENSIONS", foo.value
  end

  def test_format
    input = " format  NCHAR= 10"
    lexer = NexusParser::Lexer.new(input)
    assert foo = lexer.pop(NexusParser::Tokens::Format)
    assert_equal  "format", foo.value
  end

  def test_odd_value_pair
    lexer = NexusParser::Lexer.new(" TEXT   CHARACTER = 3 TEXT = A62.003;

                        TEXT   CHARACTER = 4 TEXT = A62.004; \n     end;   ")
    assert foo = lexer.pop(NexusParser::Tokens::Label)
    assert foo = lexer.pop(NexusParser::Tokens::ValuePair)
    blorf = {:character => "3"}
    assert_equal blorf , foo.value
    assert foo = lexer.pop(NexusParser::Tokens::ValuePair)
    blorf = {:text => "A62.003"}
    assert_equal blorf , foo.value
    assert foo = lexer.pop(NexusParser::Tokens::Label)
    assert_equal "TEXT", foo.value
    assert foo = lexer.pop(NexusParser::Tokens::ValuePair)
    blorf = {:character => "4"}
    assert_equal blorf , foo.value
    assert foo = lexer.pop(NexusParser::Tokens::ValuePair)
    blorf = {:text => "A62.004"}
    assert_equal blorf , foo.value

  end


  def test_value_pair

    lexer0 = NexusParser::Lexer.new(' DATATYPE=STANDARD ')
    assert foo = lexer0.pop(NexusParser::Tokens::ValuePair)
    blorf = {:datatype => "STANDARD"}
    assert_equal blorf , foo.value

    lexer = NexusParser::Lexer.new(' DATATYPE = STANDARD ')
    assert foo = lexer.pop(NexusParser::Tokens::ValuePair)
    blorf = {:datatype => "STANDARD"}
    assert_equal blorf , foo.value

    lexer2 = NexusParser::Lexer.new(' DATATYPE ="STANDARD" ')
    assert foo = lexer2.pop(NexusParser::Tokens::ValuePair)
    assert_equal blorf, foo.value

    lexer3 = NexusParser::Lexer.new('DATATYPE= "STANDARD" ')
    assert foo = lexer3.pop(NexusParser::Tokens::ValuePair)
    assert_equal blorf, foo.value

    input= "   NCHAR=10 ntaxa =10 nfoo='999' nbar = \" a b c  \" ;  "
    lexer4 = NexusParser::Lexer.new(input)
    assert foo = lexer4.pop(NexusParser::Tokens::ValuePair)
    smorf = {:nchar => '10'}
    assert_equal smorf, foo.value
    assert foo = lexer4.pop(NexusParser::Tokens::ValuePair)
    smorf = {:ntaxa => '10'}
    assert_equal smorf, foo.value
    assert foo = lexer4.pop(NexusParser::Tokens::ValuePair)
    smorf = {:nfoo => '999'}
    assert_equal smorf, foo.value
    assert foo = lexer4.pop(NexusParser::Tokens::ValuePair)
    smorf = {:nbar => 'a b c'}
    assert_equal smorf, foo.value

    lexer5 = NexusParser::Lexer.new(' symbols= " a c b d 1 " ')
    assert foo = lexer5.pop(NexusParser::Tokens::ValuePair)
    smorf = {:symbols => 'a c b d 1'}
    assert_equal smorf, foo.value

    lexer6 = NexusParser::Lexer.new(' missing = - ')
    assert foo = lexer6.pop(NexusParser::Tokens::ValuePair)
    smorf = {:missing => '-'}
    assert_equal smorf, foo.value

    lexer6a = NexusParser::Lexer.new("ntaxa=1;\n")
    assert foo = lexer6a.pop(NexusParser::Tokens::ValuePair)
    smorf = {:ntaxa => '1'}
    assert_equal smorf, foo.value

    lexer7 = NexusParser::Lexer.new("ntaxa =1;\n")
    assert foo = lexer7.pop(NexusParser::Tokens::ValuePair)
    smorf = {:ntaxa => '1'}
    assert_equal smorf, foo.value

    lexer8 = NexusParser::Lexer.new(" ntaxa = 1 ;\n")
    assert foo = lexer8.pop(NexusParser::Tokens::ValuePair)
    smorf = {:ntaxa => '1'}
    assert_equal smorf, foo.value

    lexer9 = NexusParser::Lexer.new(" TF = (CM 'This is an annotation that haa a hard return in it^n^n^n^nSo there!') ")
    assert foo = lexer9.pop(NexusParser::Tokens::ValuePair)
    smorf = {:tf => "(CM 'This is an annotation that haa a hard return in it^n^n^n^nSo there!')" }
    assert_equal smorf, foo.value

    lexer10 = NexusParser::Lexer.new(" TF = (CM 'This is an value pair that has (parens) within the value, twice! ()') ; some stuff left here ")
    assert foo = lexer10.pop(NexusParser::Tokens::ValuePair)
    smorf = {:tf => "(CM 'This is an value pair that has (parens) within the value, twice! ()')" }
    assert_equal smorf, foo.value

    lexer11 = NexusParser::Lexer.new("CHARACTER = 1 TEXT = A62.001;")
    assert_equal true, !lexer11.peek(NexusParser::Tokens::SemiColon)
    assert_equal true, lexer11.peek(NexusParser::Tokens::ValuePair)
    assert foo = lexer11.pop(NexusParser::Tokens::ValuePair)
    smorf = {:character => "1" }
    assert_equal smorf, foo.value
    assert foo = lexer11.pop(NexusParser::Tokens::ValuePair)
  end

  def test_MesquiteIDs
    lexer = NexusParser::Lexer.new('IDS JC1191fcddc3b425 JC1191fcddc3b426 JC1191fcddc3b427 JC1191fcddc3b428 JC1191fcddc3b429 JC1191fcddc3b430 JC1191fcddc3b431 JC1191fcddc3b432 JC1191fcddc3b433 JC1191fcddc3b434 ;
      BLOCKID JC1191fcddc0c0;')
    assert lexer.pop(NexusParser::Tokens::MesquiteIDs)
    assert lexer.pop(NexusParser::Tokens::MesquiteBlockID)
  end

  def test_TreesBlk
    lexer = NexusParser::Lexer.new("BEGIN TREES;
      Title Imported_trees;
      LINK Taxa = 'Scharff&Coddington_1997_Araneidae';
      TRANSLATE
        1 Dictyna,
        2 Uloborus,
        3 Deinopis,
        4 Nephila&Herennia,
        5 'Nephilengys_cruentata',
        6 Meta,
        7 Leucauge_venusta,
        8 Pachygnatha,
        9 'Theridiosoma_01',
        10 Tetragnatha;
      TREE 'Imported tree 1+' = (1,((2,3),(((4,5),(6,(7,(8,10)))),9)));
      TREE 'Imported tree 2+' = (1,((2,3),(((4,5),(6,(7,(8,10)))),9)));
      TREE 'Imported tree 3+' = (1,((2,3),(((6,(4,5)),(7,(8,10))),9)));
      TREE 'Imported tree 4+' = (1,((2,3),(((4,5),(6,(7,(8,10)))),9)));
      TREE 'Imported tree 5+' = (1,((2,3),(((6,(4,5)),(7,(8,10))),9)));
      TREE 'Imported tree 6+' = (1,((2,3),(((4,5),(6,(7,(8,10)))),9)));
      TREE 'Imported tree 7+' = (1,((2,3),(((6,(4,5)),(7,(8,10))),9)));
      TREE 'Imported tree 8+' = (1,((2,3),(((6,(4,5)),(7,(8,10))),9)));

    END;


    BEGIN LABELS;
      CHARGROUPLABEL MM_Genitalia COLOR = (RGB 1.0 0.4 0.4) ;
      CHARGROUPLABEL Somatic COLOR = (RGB 0.6 1.0 0.33333333) ;
      CHARGROUPLABEL Spinnerets COLOR = (RGB 0.46666667 0.57254902 1.0) ;
      CHARGROUPLABEL Behavior COLOR = (RGB 1.0 0.46666667 1.0) ;


    END;")

    assert lexer.pop(NexusParser::Tokens::BeginBlk)
    assert foo = lexer.pop(NexusParser::Tokens::TreesBlk)
    assert_equal 'TREES', foo.value.slice(0,5)
    assert_equal 'END;', foo.value.slice(-4,4)
    assert lexer.pop(NexusParser::Tokens::BeginBlk)
    assert lexer.pop(NexusParser::Tokens::LabelsBlk)

  end

  def test_NotesBlk
    input = "BEGIN NOTES ;"
    lexer = NexusParser::Lexer.new(input)
    assert lexer.pop(NexusParser::Tokens::BeginBlk)
    assert foo = lexer.pop(NexusParser::Tokens::NotesBlk)
    assert "NOTES", foo.value
  end

  def test_LabelsBlk
    lexer = NexusParser::Lexer.new("
      LABELS;
        CHARGROUPLABEL MM_Genitalia COLOR = (RGB 1.0 0.4 0.4) ;
        CHARGROUPLABEL Somatic COLOR = (RGB 0.6 1.0 0.33333333) ;
        CHARGROUPLABEL Spinnerets COLOR = (RGB 0.46666667 0.57254902 1.0) ;
        CHARGROUPLABEL Behavior COLOR = (RGB 1.0 0.46666667 1.0) ;


      ENDBLOCK;

    BEGIN some other block;")

    assert foo = lexer.pop(NexusParser::Tokens::LabelsBlk)
    assert_equal 'LABELS', foo.value.slice(0,6)
    assert_equal 'ENDBLOCK;', foo.value.slice(-9,9)
  end

  def test_SetsBlk
    lexer = NexusParser::Lexer.new("
          SETS;
      CHARPARTITION * UNTITLED  =  Somatic :  1 -  2 4, MM_Genitalia :  5 -  8 10;

      END;
    BEGIN some other block;")

    assert foo = lexer.pop(NexusParser::Tokens::SetsBlk)
    assert_equal 'SETS', foo.value.slice(0,4)
    assert_equal 'END;', foo.value.slice(-4,4)
  end

  def test_lexer_errors
    lexer = NexusParser::Lexer.new("*&")
    assert_raise(NexusParser::ParseError) {lexer.peek(NexusParser::Tokens::Label)}
  end
end


class Test_Parser < Test::Unit::TestCase
  def setup
    # a Mesquite 2.n or higher file
    @nf = File.read(File.expand_path(File.join(File.dirname(__FILE__), '../test/MX_test_03.nex')))
  end

  def teardown
    @nf = nil
  end

  def test_that_file_might_be_nexus
    begin
      assert !parse_nexus_file("#Nexblux Begin Natrix end;")
    rescue NexusParser::ParseError
      assert true
    end
  end

  def test_parse_initializes
    parse_nexus_file(@nf)
  end

  def test_parse_file
    # this is the major loop, all parts should exist
    foo = parse_nexus_file(@nf)

    assert_equal 10, foo.taxa.size
    assert_equal 10, foo.characters.size
    assert_equal 10, foo.codings.size
    assert_equal 1, foo.taxa[1].notes.size # asserts that notes are parsing
    assert_equal "norm", foo.characters[0].states["0"].name
    assert_equal "modified", foo.characters[0].states["1"].name
  end

  def test_parse_authors_blk
  end

  def test_taxa_block
    # we've popped off the header already
    input =
      "TITLE 'Scharff&Coddington_1997_Araneidae';
        DIMENSIONS NTAX=10;
        TAXLABELS
          Dictyna Uloborus Deinopis Nephila&Herennia 'Nephilengys_cruentata' Meta Leucauge_venusta Pachygnatha 'Theridiosoma_01' Tetragnatha
        ;
        IDS JC1191fcddc2b128 JC1191fcddc2b129 JC1191fcddc2b130 JC1191fcddc2b131 JC1191fcddc2b132 JC1191fcddc2b133 JC1191fcddc2b134 JC1191fcddc2b135 JC1191fcddc2b137 JC1191fcddc2b136 ;
        BLOCKID JC1191fcddc0c4;
      END;"

    builder = NexusParser::Builder.new
    lexer = NexusParser::Lexer.new(input)
    NexusParser::Parser.new(lexer,builder).parse_taxa_blk
    foo = builder.nexus_file

    assert_equal 10, foo.taxa.size
    assert_equal "Dictyna", foo.taxa[0].name
    assert_equal "Nephilengys_cruentata", foo.taxa[4].name
    assert_equal "Theridiosoma_01", foo.taxa[8].name
    assert_equal "Tetragnatha", foo.taxa[9].name
  end

  def test_taxa_block_without_IDS
    # we've popped off the header already
    input =
      "TITLE 'Scharff&Coddington_1997_Araneidae';
        DIMENSIONS NTAX=10;
        TAXLABELS
          Dictyna Uloborus Deinopis Nephila&Herennia 'Nephilengys_cruentata' Meta Leucauge_venusta Pachygnatha 'Theridiosoma_01' Tetragnatha
        ;
      END;"

    builder = NexusParser::Builder.new
    lexer = NexusParser::Lexer.new(input)
    NexusParser::Parser.new(lexer,builder).parse_taxa_blk
    foo = builder.nexus_file

    assert_equal 10, foo.taxa.size
    assert_equal "Dictyna", foo.taxa[0].name
    assert_equal "Nephilengys_cruentata", foo.taxa[4].name
    assert_equal "Theridiosoma_01", foo.taxa[8].name
    assert_equal "Tetragnatha", foo.taxa[9].name
  end

  def test_parse_characters_blk
    input=  "
      TITLE  'Scharff&Coddington_1997_Araneidae';
      DIMENSIONS  NCHAR=10;
      FORMAT DATATYPE = STANDARD GAP = - MISSING = ? SYMBOLS = \"  0 1 2 3 4 5 6 7 8 9 A\";
      CHARSTATELABELS
        1 Tibia_II /  norm modified, 2 TII_macrosetae /  '= TI' stronger, 3 Femoral_tuber /  abs pres 'm-setae', 5 Cymbium /  dorsal mesal lateral, 6 Paracymbium /  abs pres, 7 Globular_tegulum /  abs pres, 8  /  entire w_lobe, 9 Conductor_wraps_embolus, 10 Median_apophysis /  pres abs;
      MATRIX
      Dictyna                0?00201001
      Uloborus               0?11000000
      Deinopis               0?01002???
      Nephila&Herennia       0?21010011
      'Nephilengys_cruentata'0?(0,1)1010(0,1,2)11
      Meta                   0?01A10011
      Leucauge_venusta       ???--?-??-
      Pachygnatha            0?210(0 1)0011
      'Theridiosoma_01'      ??????????
      Tetragnatha            0?01011011

    ;
      IDS JC1191fcddc3b425 JC1191fcddc3b426 JC1191fcddc3b427 JC1191fcddc3b428 JC1191fcddc3b429 JC1191fcddc3b430 JC1191fcddc3b431 JC1191fcddc3b432 JC1191fcddc3b433 JC1191fcddc3b434 ;
      BLOCKID JC1191fcddc0c0;

    END;"

    builder = NexusParser::Builder.new
    @lexer = NexusParser::Lexer.new(input)

    # add the taxa, assumes we have them for comparison purposes, though we (shouldn't) ultimately need them
    # foo.taxa = ["Dictyna", "Uloborus", "Deinopis", "Nephila&Herennia", "Nephilenygys_cruentata", "Meta", "Leucauge_venusta", "Pachygnatha", "Theridiosoma_01", "Tetragnatha"]

    # stub the taxa, they would otherwise get added in dimensions or taxa block
    (0..9).each{|i| builder.stub_taxon}

    NexusParser::Parser.new(@lexer,builder).parse_characters_blk
    foo = builder.nexus_file

    assert_equal 10, foo.characters.size
    assert_equal "Tibia_II", foo.characters[0].name
    assert_equal "TII_macrosetae", foo.characters[1].name

    assert_equal "norm", foo.characters[0].states["0"].name
    assert_equal "modified", foo.characters[0].states["1"].name


    # ?!!?
    # foo.characters[0].states["1"].name
    assert_equal ["", "abs", "pres"], foo.characters[9].states.keys.collect{|s| foo.characters[9].states[s].name}.sort


    assert_equal ["0","1"], foo.codings[7][5].states
    assert_equal ["?"], foo.codings[9][1].states
    assert_equal ["-", "0", "1", "2", "A"], foo.characters[4].state_labels
  end

  def test_matrix_with_short_row
    input=  "
      DIMENSIONS  NCHAR=2;
      FORMAT DATATYPE = STANDARD GAP = - MISSING = ? SYMBOLS = \"  0 1 2 3 4 5 6 7 8 9 A\";
      CHARSTATELABELS
        1 Tibia_II /  norm modified, 2 TII_macrosetae /  '= TI' stronger;
      MATRIX
      Dictyna                0?
      Uloborus               ??
      Deinopis               0
    ;
    END;"

    builder = NexusParser::Builder.new
    @lexer = NexusParser::Lexer.new(input)

    # stub the taxa, they would otherwise get added in dimensions or taxa block
    (0..2).each{|i| builder.stub_taxon}

    assert_raise_with_message(NexusParser::ParseError, /too short/) {
      NexusParser::Parser.new(@lexer, builder).parse_characters_blk
    }
  end

  def test_characters_block_without_IDs_or_title
    input=  "
      DIMENSIONS  NCHAR=10;
      FORMAT DATATYPE = STANDARD GAP = - MISSING = ? SYMBOLS = \"  0 1 2 3 4 5 6 7 8 9 A\";
      CHARSTATELABELS
        1 Tibia_II /  norm modified, 2 TII_macrosetae /  '= TI' stronger, 3 Femoral_tuber /  abs pres 'm-setae', 5 Cymbium /  dorsal mesal lateral, 6 Paracymbium /  abs pres, 7 Globular_tegulum /  abs pres, 8  /  entire w_lobe, 9 Conductor_wraps_embolus, 10 Median_apophysis /  pres abs;
      MATRIX
      Dictyna                0?00201001
      Uloborus               0?11000000
      Deinopis               0?01002???
      Nephila&Herennia       0?21010011
      'Nephilengys_cruentata'0?(0,1)1010(0,1,2)11
      Meta                   0?01A10011
      Leucauge_venusta       ???--?-??-
      Pachygnatha            0?210(0 1)0011
      'Theridiosoma_01'      ??????????
      Tetragnatha            0?01011011

    ;
    ENDBLOCK;"

    builder = NexusParser::Builder.new
    @lexer = NexusParser::Lexer.new(input)

    # add the taxa, assumes we have them for comparison purposes, though we (shouldn't) ultimately need them
    # foo.taxa = ["Dictyna", "Uloborus", "Deinopis", "Nephila&Herennia", "Nephilenygys_cruentata", "Meta", "Leucauge_venusta", "Pachygnatha", "Theridiosoma_01", "Tetragnatha"]

    # stub the taxa, they would otherwise get added in dimensions or taxa block
    (0..9).each{|i| builder.stub_taxon}

    NexusParser::Parser.new(@lexer,builder).parse_characters_blk
    foo = builder.nexus_file

    assert_equal 10, foo.characters.size
    assert_equal "Tibia_II", foo.characters[0].name
    assert_equal "TII_macrosetae", foo.characters[1].name
    assert_equal "norm", foo.characters[0].states["0"].name
    assert_equal "modified", foo.characters[0].states["1"].name
    assert_equal ["", "abs", "pres"], foo.characters[9].states.keys.collect{|s| foo.characters[9].states[s].name}.sort
    assert_equal ["0","1"], foo.codings[7][5].states
    assert_equal ["?"], foo.codings[9][1].states
    assert_equal ["-", "0", "1", "2", "A"], foo.characters[4].state_labels
  end

  def test_characters_block_from_file
    foo = parse_nexus_file(@nf)
    assert_equal 10, foo.characters.size
  end

  def test_codings
    foo = parse_nexus_file(@nf)
    assert_equal 100, foo.codings.flatten.size  # two multistates count in single cells
  end

  def test_parse_dimensions
    input= " DIMENSIONS  NCHAR=10 ntaxa =10 nfoo='999' nbar = \" a b c  \" blorf=2;  "
    builder = NexusParser::Builder.new
    lexer = NexusParser::Lexer.new(input)

    NexusParser::Parser.new(lexer,builder).parse_dimensions
    foo = builder.nexus_file

    assert_equal "10", foo.vars[:nchar]
    assert_equal "10", foo.vars[:ntaxa]
    assert_equal "999", foo.vars[:nfoo]
    assert_equal 'a b c', foo.vars[:nbar]
    assert_equal '2', foo.vars[:blorf]
    # add test that nothing is left in lexer
  end

  def test_parse_format
    input = "FORMAT DATATYPE = STANDARD GAP = - MISSING = ? SYMBOLS = \"  0 1 2 3 4 5 6 7 8 9 A\";"
    builder = NexusParser::Builder.new
    lexer = NexusParser::Lexer.new(input)

    NexusParser::Parser.new(lexer,builder).parse_format
    foo = builder.nexus_file

    assert_equal "STANDARD", foo.vars[:datatype]
    assert_equal "-", foo.vars[:gap]
    assert_equal "?", foo.vars[:missing]
    assert_equal '0 1 2 3 4 5 6 7 8 9 A', foo.vars[:symbols]
    # add test that nothing is left in lexer
  end

  def test_parse_format_respect_case
    input = "FORMAT DATATYPE = STANDARD RESPECTCASE GAP = - MISSING = ? SYMBOLS = \"  0 1 2 3 4 5 6 7 8 9 A\";"
    builder = NexusParser::Builder.new
    lexer = NexusParser::Lexer.new(input)

    NexusParser::Parser.new(lexer,builder).parse_format
    foo = builder.nexus_file

    assert_equal "STANDARD", foo.vars[:datatype]
    assert_equal "-", foo.vars[:gap]
    assert_equal "?", foo.vars[:missing]
    assert_equal '0 1 2 3 4 5 6 7 8 9 A', foo.vars[:symbols]
  end

  def test_parse_chr_state_labels
    input =" CHARSTATELABELS
    1 Tibia_II /  norm modified, 2 TII_macrosetae /  '= TI' stronger, 3 Femoral_tuber /  abs pres 'm-setae', 5 Cymbium /  dorsal mesal lateral, 6 Paracymbium /  abs pres, 7 Globular_tegulum /  abs pres, 8  /  entire w_lobe, 9 Conductor_wraps_embolus, 10 Median_apophysis /  pres abs ;
    MATRIX
    fooo 01 more stuff here that should not be hit"

    builder = NexusParser::Builder.new
    lexer = NexusParser::Lexer.new(input)

    (0..9).each{builder.stub_chr()}

    NexusParser::Parser.new(lexer,builder).parse_chr_state_labels

    foo = builder.nexus_file
    assert_equal 10, foo.characters.size
    assert_equal "Tibia_II", foo.characters[0].name
    assert_equal "norm", foo.characters[0].states["0"].name
    assert_equal "modified", foo.characters[0].states["1"].name

    assert_equal "TII_macrosetae", foo.characters[1].name
    assert_equal "= TI", foo.characters[1].states["0"].name
    assert_equal "stronger", foo.characters[1].states["1"].name

    assert_equal "Femoral_tuber", foo.characters[2].name
    assert_equal "abs", foo.characters[2].states["0"].name
    assert_equal "pres", foo.characters[2].states["1"].name
    assert_equal "m-setae", foo.characters[2].states["2"].name

    assert_equal "Undefined", foo.characters[3].name
    assert_equal 0, foo.characters[3].states.keys.size

    assert_equal "Cymbium", foo.characters[4].name
    assert_equal "dorsal", foo.characters[4].states["0"].name
    assert_equal "mesal", foo.characters[4].states["1"].name
    assert_equal "lateral", foo.characters[4].states["2"].name

    assert_equal "Paracymbium", foo.characters[5].name
    assert_equal "abs", foo.characters[5].states["0"].name
    assert_equal "pres", foo.characters[5].states["1"].name

    assert_equal "Globular_tegulum", foo.characters[6].name
    assert_equal "abs", foo.characters[6].states["0"].name
    assert_equal "pres", foo.characters[6].states["1"].name

    assert_equal "Undefined", foo.characters[7].name
    assert_equal "entire", foo.characters[7].states["0"].name
    assert_equal "w_lobe", foo.characters[7].states["1"].name

    # ...

    assert_equal "Median_apophysis", foo.characters[9].name
    assert_equal "pres", foo.characters[9].states["0"].name
    assert_equal "abs", foo.characters[9].states["1"].name
  end

  def test_strange_chr_state_labels
    input =" CHARSTATELABELS
      29 'Metatarsal trichobothria (CodAra.29)' / 37623 '>2', 30 'Spinneret cuticle (CodAra.30)' /  annulate ridged squamate;
      Matrix
      fooo 01 more stuff here that should not be hit"

    builder = NexusParser::Builder.new
    lexer = NexusParser::Lexer.new(input)

    (0..29).each{builder.stub_chr()}

    NexusParser::Parser.new(lexer,builder).parse_chr_state_labels

    foo = builder.nexus_file

    assert_equal "Metatarsal trichobothria (CodAra.29)", foo.characters[28].name
    assert_equal "37623", foo.characters[28].states["0"].name
    assert_equal ">2", foo.characters[28].states["1"].name

    assert_equal "Spinneret cuticle (CodAra.30)", foo.characters[29].name
    assert_equal "annulate", foo.characters[29].states["0"].name
    assert_equal "ridged", foo.characters[29].states["1"].name
    assert_equal "squamate", foo.characters[29].states["2"].name

  end

  # https://github.com/mjy/nexus_parser/issues/9
  def test_three_both_numeric_and_label_state_names_in_a_row
    input =" CHARSTATELABELS
    1 'Metatarsal trichobothria (CodAra.29)' / 3 9 27 asdf;
    Matrix
    fooo 01 more stuff here that should not be hit"

    builder = NexusParser::Builder.new
    lexer = NexusParser::Lexer.new(input)

    builder.stub_chr()

    NexusParser::Parser.new(lexer, builder).parse_chr_state_labels

    foo = builder.nexus_file

    assert_equal "3", foo.characters[0].states['0'].name
    assert_equal "9", foo.characters[0].states['1'].name
    assert_equal "27", foo.characters[0].states['2'].name
    assert_equal "asdf", foo.characters[0].states['3'].name
  end

  def DONT_test_parse_really_long_string_of_chr_state_labels
    input =" CHARSTATELABELS
    1 Epigynal_ventral_margin /  'entire (Fig. 15G)' 'with scape (Fig. 27D)', 2 Epigynal_external_structure /  openings_on_a_broad_depression 'copulatory openings on plate, flush with abdomen, sometimes slit like', 3 Epigynal_depression /  'round or square, at most slightly wider than high ' 'elongate, at least twice as wide as high ', 4 Epigynal_plate_surface /  'smooth (Fig. 12E)' 'ridged (Fig. 21G)', 5 epignynal_septum /  absent_ present_, 6 Copulatory_bursa_anterior_margin /  'entire, broadly transverse (Fig. 19B)' 'medially acute (Figs. 22G, 40B)', 7 'Copulatory duct: spermathecal junction' /  posterior lateral_or_anterior, 8 Copulatory_duct_loops_relative_to_spermathecae /  apart 'encircling (Fig. 93J)', 9 Copulatory_duct_terminal_sclerotization /  as_rest_of_duct_ 'distinctly sclerotized, clearly more than rest of duct ', 10 Hard_sclerotized_CD_region /  mostly_or_entirely_ectal_to_the_ectal_rim_of_the_spermathecae 'caudal to the spermathecae, mesal to ectal margin of spermathecae', 11 Male_palpal_tibial_rim /  uniform_or_only_slightly_asymmetric 'strongly and asymmetrically protruding, scoop-shaped (Fig 36D)', 12 Male_palpal_tibia_prolateral_trichobothria /  one none, 13 Cymbial_ridge_ectal_setae /  unmodified 'strongly curved towards the palpal bulb (Kochiura, Figs. 51B-C, 52C)', 14 Cymbial_distal_promargin /  entire 'with an apophysis (Argyrodes, Figs.) ', 15 Cymbial_mesal_margin /  entire 'incised (Anelosimus, Figs. 17D, 20A) ' deeply_notched, 16 Cymbial_tip_sclerotization /  like_rest_of_cymbium 'lightly sclerotized, appears white', 17 Cymbial_tip_setae /  like_other_setae 'thick and strongly curved (Kochiura, Figs. 51B, 52C)', 18 Cymbial_sheath /  absent present, 19 Lock_placement /  'distal (Figs. 67B, 92F-G, I, M)' 'central (Fig. 92H)', 20 Lock_mechanism /  'hook (Figs 31F, 60D, 91A, 92D-E, J-L)' 'hood (Figs 18A, 75B, 92F-I, M)' 'Theridula (Fig 81D)', 21 Cymbial_hook_orientation /  'facing downwards (Figs. 91A, 92D-E, J-K)' 'facing upwards (Fig. 60C-D, 92L)', 22 Cymbial_hook_location /  'inside cymbium (Fig. 92D-E, J-K)' 'ectal cymbial margin (Figs. 67B, 92L).', 23 Cymbial_hook_distal_portion /  'blunt (Figs. 31F, 92D-E)' 'tapering to a narrow tongue (Figs. 66B, 67D, 92L)', 24 Cymbial_hood_size /  'narrow (Fig. 92F-H)' 'broad (Fig. 92I)' 'Spintharus (Fig. 92M)', 25 Cymbial_hood_region /  'translucent, hood visible through cymbium (Anelosimus, Figs. 90A, 91C)' 'opaque, hood not visible', 26 Alveolus_shape /  'circular or oval (Fig. 92A-H)' 'with a mesal extension (Fig. 92A)', 27 Tegulum_ectal_margin /  entire 'protruded (Fig. 20D)', 28 Tegular_groove /  absent 'present (Fig. 28B)', 29 SDT_SB_I /  separate touching, 30 'SDT post-SB II turn' /  gradual '90 degrees (Anelosimus, Fig. 93B)', 31 SDT_SB_I_&_II_reservoir_segment_alignment /  divergent parallel, 32 SDT_SB_I_&_II_orientation /  in_plane_of_first_loop_from_fundus 'out of plane of first loop, against tegular wall', 33 SDT_RSB_I_&_II /  absent present, 34 SDT_SB_III /  absent present, 35 SDT_SB_IV /  absent 'present (Fig. 93E)', 36 Conductor_shape /  'simple, round or oval, short' 'fan shaped, narrow base and broad tip (Selkirkiella, Kochiura)' Enoplognatha Argyrodes Achaearanea Theridion '''rupununi''' '''tanzania''' '''cup-shaped''', 37 Conductor /  'with a groove for embolus (Figs. 10A, 28D, 69B)' 'entire (Figs. 13D, 17F, 52C-D)', 38 Conductor_surface /  'smooth (Figs. 75B, 77B-C)' ' heavily ridged (Figs. 10B-C, 44D. 67C, 69D)', 39 Conductor_tip_sclerotization /  like_base more_than_base, 40 Subconductor /  absent present, 41 Subconductor_pit_upper_wall /  'entire, or slightly protruding' forms_a_regular_oval_lip, 42 Subconductor_at_C_base /  narrows_abruptly_before_C_base narrows_gradually_along_its_entire_length broad_at_base, 43 'Embolus tail-SC relation' /  'hooked in, or oriented towards SC' surpasses_SC behind_E_base, 44 Tegulum_ectally_ /  occupying_less_than_half_of_the_cymbial_cavity_ occupying_more_than_half_of_the_cymbial_cavity, 45 MA_and_sperm_duct /  sperm_duct_loop_not_inside_MA 'sperm duct loop inside MA (Figs. 90F, 91B)', 46 'MA-tegular membrane connection' /  broad narrow, 47 MA_form /  unbranched 'two nearly equally sized branches (Fig. 22A-B) ', 48 MA_distal_tip /  entire hooded, 49 MA_hood_form /  'narrow, pit-like (Figs. 31F, 34D)' 'scoop-shaped (Figs. 60D, 66B, 67D)', 50 TTA_form /  entire 'grooved (Fig. 44C)', 51 TTA /  bulky 'prong shaped (vittatus group)', 52 TTA_distal_tip /  entire_or_gently_curved Argyrodes 'hooked (branched)', 53 TTA_hook_distal_branch /  barely_exceeding_lower_branch_ 'extending beyond lower branch (jucundus group) ', 54 TTA_hook_distal_branch /  thick_ 'thin, finger like (domingo, dubiosus)', 55 TTA_hook_proximal_branch /  'blunt, broad' 'flattened, bladelike' 'cylindrical, elongated', 56 TTA_surface_subterminally /  smooth ridged, 57 TTA_tip_surface /  smooth 'ridged (Figs. 7A-B, 17F, 31D, 34D, 54A, 56B, 86A)', 58 Embolus_and_TTA /  loosely_associated_to_or_resting_in_TTA_shallow_groove 'parts of E entirely enclosed in TTA (Figs. 37A-B, 44C, 89C)', 59 Embolus_tip_surface /  smooth denticulate, 60 Embolus_spiral_curviture /  gentle whip_like corkscrew, 61 Embolus_tip /  entire bifid, 62 Embolus_origin /  retroventral_on_tegulum 'retrolateral (ectal), partially or completely hidden by cymbium (Figs 44C, 60A-C, 67B)', 63 Embolus_ridges /  absent present, 64 Embolus_shape /  short_to_moderately_elongate 'extremely long, >2 spirals (Figs. 54D, 73A-E)', 65 Embolus_spiral_width /  'thin, much of E spiral subequal to E tip ' 'thick, entire E spiral much broader than tip ', 66 Embolus_distal_rim /  'entire (normal)' deeply_grooved, 67 Embolic_terminus /  abrupt 'with a distal apophysis (EA, Fig. 34E) ', 68 Embolus_tail /  'entire, smooth' 'distinct, lobed', 69 'Embolus-dh connection grooves' /  absent present, 70 'Embolus-dh grooves' /  'deep, extend into the E base more than twice longer than the distance between them' 'short, extend into the E base about as long, or slightly longer than the distance between them', 71 E_spiral_distally /  'relatively thin or filiform, cylindrical' 'thick, not cylindrical' 'rupununi/lorenzo like', 72 Embolus_spiral /  entire 'biparted (Eb)' pars_pendula, 73 Eb_orientation /  towards_embolus_tip towards_tibia, 74 Embolic_division_b /  separates_early_from_E E_and_Eb_tightly_associated_the_entire_spiral, 75 Embolic_division_b /  broad 'narrow, relative to Eb spiral, snout-like', 76 'Eb distal portion, ectal marginl' /  'level, not raised ' with_a_distinct_ridge_, 77 Eb_form /  flat 'globose, inflated', 78 Eb_form /  'distinct, clearly separate apophysis' 'short, confined to first section of spiral, barely separate', 79 Eb_tip_and_E_tip_association /  separate Eb_and_E_tips_juxtaposed 'E tip rests on Eb ''cup''', 80 Eb_snout /  'short, snug with E spiral ' 'long, separate from E spiral ', 81 Distal_portion_of_Eb /  entire with_a_cup_shaped_apophysis with_a_raised_ridge, 82 E_tail /  lobe_not_reaching_ectal_margin_of_Eb_ lobe_touching_ectal_margin_of_Eb_, 83 Extra_tegular_sclerite /  absent_ present_, 84 'Median eyes (male)' /  flush_with_carapace 'on tubercle (Argyrodes)', 85 'AME size (male)' /  subequal_or_slightly_larger_than_ALE clearly_smaller_than_ALE, 86 Cheliceral_posterior_margin /  toothed smooth, 87 Cheliceral_posterior_tooth_number /  three_or_more two one, 88 Cheliceral_furrow /  smooth denticulate, 89 Carapace_hairiness /  'sparsely or patchily hirsute (Fig. 48D)' 'uniformly hirsute (Fig. 71D)', 90 Carapace_pars_stridens /  irregular regular_parallel_ridges, 91 Interocular_area /  more_or_less_flush_with_clypeus projecting_beyond_clypeus, 92 Clypeus /  concave_or_flat with_a_prominent_projection, 93 'ocular and clypeal region setae distribution (male)' /  sparse 'in a dense field, or fields', 94 'Labium-sternum connection' /  'visible seam  (Fig. 27C)' fused, 95 Sternocoxal_tubercles /  present absent, 96 Pedicel_location /  'anterior (Fig. 94A-D)' 'medial (Fig. 94J-K)', 97 Abdominal_folium_pattern /  bilateral_spots_or_blotches distinct_central_band_, 98 Abdomen_pattern /  Anelosimus_, 99 Dorsal_band /  'dark edged by white (Kochiura, Anelosimus, Fig. 94G, J)' 'light edged by dark (Fig. 94H)' 'Ameridion, light edged by white (Fig. 94I)', 100 Abdominal_dot_pigment /  silver 'non-reflective, dull', 101 SPR_form /  'weakly keeled (Figs. 67F, 74F)' 'strongly keeled and elongate (Figs. 16B-C, 24D-E, 42F)', 102 SPR_pick_number /  '1-4' '6-28' '>30', 103 SPR_insertion /  flush_with_abdominal_surface 'on a ridge (Figs 32D, 72A-B)', 104 'SPR mesally-oriented picks' /  absent present, 105 'SPR mesally-oriented picks relative to sagittal plane' /  angled_dorsally perpendicular_or_angled_ventrally, 106 SPR /  straight_or_slightly_irregular distinctly_curved 'argyrodine, dorsal picks aside others', 107 SPR_dorsal_pick_spacing /  subequal_to_ventral_pick_spacing distinctly_compressed, 108 SPR_relative_to_pedicel /  lateral dorsal, 109 SPR_setae /  separate tight, 110 'Supra pedicillate ventrolateral  (4 o''clock) proprioreceptor' /  absent present, 111 Epiandrous_fusule_arrangement /  in_one_pair_of_sockets in_a_row, 112 Epiandrous_fusule_pair_number /  '=>9' '6-8' '4-5' 1, 113 Colulus /  'present (Figs. 45E, 61F)' 'absent (Figs. 16E, 78A)' 'invaginated (Figs. 9D,  63G)', 114 Colulus_size /  'large and fleshy (Figs. 55H, 61F)' 'small, less than half the length of its setae (Fig. 38B)', 115 Colular_setae /  present absent, 116 'Colular setae number (female)' /  three_or_more two_, 117 'Palpal claw dentition (female)' /  'dense, > half of surface covered by denticles (Figs. 2D, 9E, 11D, 12G, 45G, 47E, 58G, 80D)' 'sparse < half of surface with denticles', 118 'Palpal tibial trichobothria (female)' /  four three two five, 119 Femur_I_relative_to_II /  subequal 'robust, clearly larger than femur II', 120 'Leg IV relative length (male)' /  '3rd longest (typical leg formula 1243)' '2nd longest (typical leg formula 1423)' 'longest (typical leg formula 4123)', 121 'Leg IV relative length (female)' /  3rd_longest 2nd_longest longest_, 122 'Femur vs. metatarsus length (female)' /  metatarsus_longer metatarsus_shorter, 123 'Femur vs. metatarsus length (male)' /  metatarsus_longer metatarsus_shorter, 124 'Metatarsus vs. tibia length (female)' /  metatarsus_longer metatarsus_shorter, 125 'Metatarsus vs. tibia length (male)' /  metatarsus_longer metatarsus_shorter, 126 Metatarsal_ventral_macrosetae /  like_other_macrosetae thickened_ventrally, 127 Tarsus_IV_comb_serrations /  'simple, straight' curved_hooks, 128 Tarsal_organ_size /  'smaller than setal sockets (normal)' enlarged, 129 'Tarsus IV central claw vs. laterals (male)' /  'short, at most subequal' 'elongate, longer (Figs. 19E, 21C, 23D, 32H, 57F, 58F)', 130 'Tarsus IV central claw vs. laterals (female)' /  equal_or_shorter stout_and_distinctly_longer minute, 131 Spinneret_insertion /  abdominal_apex 'subapical, abdomen extending beyond spinnerets', 132 PLS_flagelliform_spigot_length /  subequal_to__PLS_CY 'longer than PLS CY (Figs. 68E, 78B, 82D)', 133 'PLS, PMS CY spigot bases' /  'not modified, subequal or smaller than ampullates' 'huge and elongated, much larger than ampullates ', 134 CY_shaft_surface /  smooth grooved, 135 PLS_AC_spigot_number /  five_or_more four_or_less, 136 PLS_flagelliform_spigot /  present absent, 137 PLS_posterior_AG_spigot_shape /  'normal, round' flattened, 138 PLS_theridiid_type_AG_position /  more_or_less_parallel end_to_end, 139 'PMS minor ampullate (mAP) spigot shaft length' /  'short, subequal to CY shaft' clearly_longer_than_any_CY_shaft, 140 Web_form /  'linyphioid-like sheet web (Fig. 99C)' 'cobweb (Figs. 97G, 99A-B, 100A-F, 101A-E)' 'network mesh web - with foraging field below (rupununi/lorenzo)' 'dry line-web', 141 'Knock-down lines' /  absent present, 142 Sticky_silk_in_web /  present absent, 143 Egg_sac_surface /  spherical_to_lenticular 'stalked (Fig. 88E, 98D).', 144 Egg_case_structure /  suboval_or_roundish basal_knob rhomboid elongated Spiky, 145 Web_construction /  solitary communal, 146 Mating_thread /  present absent, 147 Adult_females_per_nest /  one multiple, 148 cooperative_behavior /  solitary subsocial permanent_sociality ;
    MATRIX
    fooo 01 more stuff here that should not be hit"

    builder = NexusParser::Builder.new
    lexer = NexusParser::Lexer.new(input)

    (0..147).each{builder.stub_chr()}

    NexusParser::Parser.new(lexer,builder).parse_chr_state_labels

    foo = builder.nexus_file
    assert_equal 10, foo.characters.size
    assert_equal "Tibia_II", foo.characters[0].name
    assert_equal "norm", foo.characters[0].states["0"].name
    assert_equal "modified", foo.characters[0].states["1"].name

    assert_equal "TII_macrosetae", foo.characters[1].name
    assert_equal "= TI", foo.characters[1].states["0"].name
    assert_equal "stronger", foo.characters[1].states["1"].name

    assert_equal "Femoral_tuber", foo.characters[2].name
    assert_equal "abs", foo.characters[2].states["0"].name
    assert_equal "pres", foo.characters[2].states["1"].name
    assert_equal "m-setae", foo.characters[2].states["2"].name

    assert_equal "Undefined", foo.characters[3].name
    assert_equal 0, foo.characters[3].states.keys.size

    assert_equal "Cymbium", foo.characters[4].name
    assert_equal "dorsal", foo.characters[4].states["0"].name
    assert_equal "mesal", foo.characters[4].states["1"].name
    assert_equal "lateral", foo.characters[4].states["2"].name

    assert_equal "Paracymbium", foo.characters[5].name
    assert_equal "abs", foo.characters[5].states["0"].name
    assert_equal "pres", foo.characters[5].states["1"].name

    assert_equal "Globular_tegulum", foo.characters[6].name
    assert_equal "abs", foo.characters[6].states["0"].name
    assert_equal "pres", foo.characters[6].states["1"].name

    assert_equal "Undefined", foo.characters[7].name
    assert_equal "entire", foo.characters[7].states["0"].name
    assert_equal "w_lobe", foo.characters[7].states["1"].name

    # ...

    assert_equal "Median_apophysis", foo.characters[9].name
    assert_equal "pres", foo.characters[9].states["0"].name
    assert_equal "abs", foo.characters[9].states["1"].name
  end



  def test_parse_notes_blk
    input ="
      TEXT  TAXA = 'Scharff&Coddington_1997_Araneidae' TAXON = 2 TEXT = 'This is a footnote to taxon 2, Uloborus';

      TEXT   TAXON = 4 CHARACTER = 8 TEXT = This_is_a_footnote_to_a_cell.;

      TEXT   CHARACTER = 10 TEXT = This_is_footnote_to_char_10;

      TEXT  FILE TEXT = 'Scharff, N. and J. A. Coddington. 1997. A phylogenetic analysis of the orb-weaving spider family Araneidae (Arachnida, Araneae). Zool. J. Linn. Soc. 120(4): 355?434';

      AN T = 4  A = JC DC = 2008.4.13.20.31.19 DM = 2008.4.13.20.31.38 ID = 01194a57d0161 I = _ TF = (CM 'This is an \"annotation\" to taxon 4') ;

      AN C = 4  A = JC DC = 2008.4.13.20.31.50 DM = 2008.4.13.20.32.10 ID = 01194a584b9f2 I = _ TF = (CM 'This is an annotation to charcter 4, that has no name.') ;

      AN T = 9 C = 3  A = 0 DC = 2008.4.20.17.24.36 DM = 2008.4.20.17.25.4 ID = 01196db963874 I = _ TF = (CM 'This is an annotation to chr 3, taxa 9, coded ?') ;

      AN T = 2 C = 6  A = JC DC = 2008.4.13.20.35.20 DM = 2008.4.13.20.35.36 ID = JC1194a5b7e1a3 I = _ TF = (CM 'This is an annotation that haa a hard return in it^n^n^n^nSo there!') ;

      AN T = 7 C = 10  A = 0 DC = 2008.4.20.17.25.11 DM = 2008.4.20.17.26.1 ID = 01196db9ebd25 I = _ TF = (CM 'this is an annotation^nwith several hard returns^nfor a cell of taxa 6, chr 9 (from zero)^ncoded as -') ;

      AN T = 2 C = 6  A = JC DC = 2008.4.13.20.35.20 DM = 2008.4.13.20.35.36 ID = JC1194a5b7e1a3 I = _ TF = (CM 'This is ANOTHER annotation that haa a hard return in it^n^n^n^nSo there!') ;

    END; Don't parse this bit, eh?"

    # note the second last note note embedds parens in the value

    builder = NexusParser::Builder.new
    lexer = NexusParser::Lexer.new(input)

    # stubs
    (0..9).each{builder.stub_chr()}
    (0..9).each{builder.stub_taxon()}
    builder.nexus_file.codings[3] = []
    builder.nexus_file.codings[3][7] = NexusParser::NexusParser::Coding.new()
    builder.nexus_file.codings[8] = []
    builder.nexus_file.codings[8][2] = NexusParser::NexusParser::Coding.new()
    builder.nexus_file.codings[1] = []
    builder.nexus_file.codings[1][5] = NexusParser::NexusParser::Coding.new()
    builder.nexus_file.codings[6] = []
    builder.nexus_file.codings[6][9] = NexusParser::NexusParser::Coding.new()
    builder.nexus_file.codings[3] = []
    builder.nexus_file.codings[3][7] = NexusParser::NexusParser::Coding.new()

    NexusParser::Parser.new(lexer,builder).parse_notes_blk

    foo = builder.nexus_file

    # make sure stubs are setup
    assert_equal 10, foo.characters.size
    assert_equal 10, foo.taxa.size

    assert_equal 1, foo.taxa[1].notes.size
    assert_equal 1, foo.codings[3][7].notes.size
    assert_equal 'This_is_a_footnote_to_a_cell.', foo.codings[3][7].notes[0].note

    assert_equal 1, foo.characters[9].notes.size
    assert_equal 'This_is_footnote_to_char_10', foo.characters[9].notes[0].note

    assert_equal 1, foo.notes.size
    assert_equal 'Scharff, N. and J. A. Coddington. 1997. A phylogenetic analysis of the orb-weaving spider family Araneidae (Arachnida, Araneae). Zool. J. Linn. Soc. 120(4): 355?434', foo.notes[0].note

    assert_equal 1, foo.taxa[3].notes.size
    assert_equal 1, foo.characters[3].notes.size
    assert_equal 1, foo.codings[8][2].notes.size
    assert_equal 1, foo.codings[6][9].notes.size
    assert_equal 2, foo.codings[1][5].notes.size # TWO!!
    assert_equal 1, foo.codings[3][7].notes.size


    assert_equal "This_is_a_footnote_to_a_cell.", foo.codings[3][7].notes[0].note

    assert_equal "This is an annotation to chr 3, taxa 9, coded ?", foo.codings[8][2].notes[0].note
    assert_equal "This is an annotation that haa a hard return in it^n^n^n^nSo there!", foo.codings[1][5].notes[0].note
    assert_equal "this is an annotation^nwith several hard returns^nfor a cell of taxa 6, chr 9 (from zero)^ncoded as -", foo.codings[6][9].notes[0].note
    assert_equal "This is ANOTHER annotation that haa a hard return in it^n^n^n^nSo there!", foo.codings[1][5].notes[1].note

  end

  def test_notes_block_2
    input="
    TEXT   CHARACTER = 1 TEXT = A62.001;
    TEXT   CHARACTER = 2 TEXT = A62.002;
    TEXT   CHARACTER = 3 TEXT = A62.003;
    TEXT   CHARACTER = 4 TEXT = A62.004;
    TEXT   CHARACTER = 5 TEXT = A62.005;
    TEXT   CHARACTER = 6 TEXT = A62.006;
    TEXT   CHARACTER = 7 TEXT = A62.007;
    TEXT   CHARACTER = 8 TEXT = A62.008;
    end;
    "

    # note the second last note note embeds parens in the value

    builder = NexusParser::Builder.new
    lexer = NexusParser::Lexer.new(input)
    # stubs
    (0..9).each{builder.stub_chr()}

    NexusParser::Parser.new(lexer,builder).parse_notes_blk

    foo = builder.nexus_file

    # make sure stubs are setup
    assert_equal 10, foo.characters.size

    assert_equal 'A62.001', foo.characters[0].notes[0].note
    assert_equal 'A62.002', foo.characters[1].notes[0].note
    assert_equal 'A62.003', foo.characters[2].notes[0].note
    assert_equal 'A62.004', foo.characters[3].notes[0].note
    assert_equal 'A62.005', foo.characters[4].notes[0].note
    assert_equal 'A62.006', foo.characters[5].notes[0].note
    assert_equal 'A62.007', foo.characters[6].notes[0].note
    assert_equal 'A62.008', foo.characters[7].notes[0].note
    assert_equal NexusParser::NexusParser::Character, foo.characters[7].class
    assert_equal 1, foo.characters[7].notes.size
  end

  def test_parse_trees_block
  end

  def test_parse_labels_block
  end

  def test_parse_sets_block
  end

  def test_parse_assumptions_block
  end

  def DONT_test_misc
    nf = File.read('foo.nex') # MX_test_01.nex
    foo = parse_nexus_file(nf)
    assert true, foo
  end

  def DONT_test_misc2
    # omit("test file doesn't currently exist")
    assert nf = File.read(File.expand_path(File.join(File.dirname(__FILE__), '../test/Aptostichus.nex')) )
    foo = parse_nexus_file(nf)
    assert true, foo
  end

end

