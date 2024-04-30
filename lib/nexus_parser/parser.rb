
class NexusParser::Parser
 
  def initialize(lexer, builder)
    @lexer = lexer
    @builder = builder
  end

  def parse_file
    # nf = @builder.new_nexus_file # create new local NexusParser instance, nf
    # blks = []
    @lexer.pop(NexusParser::Tokens::NexusStart)
     
    while @lexer.peek(NexusParser::Tokens::BeginBlk)
       
      @lexer.pop(NexusParser::Tokens::BeginBlk) # pop it
      
      if @lexer.peek(NexusParser::Tokens::AuthorsBlk)
        parse_authors_blk
        
      # we parse these below 
      elsif @lexer.peek(NexusParser::Tokens::TaxaBlk)
        
        @lexer.pop(NexusParser::Tokens::TaxaBlk )
        parse_taxa_blk
           
      elsif @lexer.peek(NexusParser::Tokens::ChrsBlk)
        @lexer.pop(NexusParser::Tokens::ChrsBlk)
        parse_characters_blk

      elsif @lexer.peek(NexusParser::Tokens::NotesBlk)
        @lexer.pop(NexusParser::Tokens::NotesBlk)  
        parse_notes_blk

      # we should parse this
      elsif @lexer.peek(NexusParser::Tokens::SetsBlk)
        @lexer.pop(NexusParser::Tokens::SetsBlk)

      # we don't parse these 
      elsif @lexer.peek(NexusParser::Tokens::TreesBlk)
        @foo =  @lexer.pop(NexusParser::Tokens::TreesBlk).value
 
      elsif @lexer.peek(NexusParser::Tokens::LabelsBlk)
        @lexer.pop(NexusParser::Tokens::LabelsBlk)
   
      elsif @lexer.peek(NexusParser::Tokens::MqCharModelsBlk)
        @lexer.pop(NexusParser::Tokens::MqCharModelsBlk) 

      elsif @lexer.peek(NexusParser::Tokens::AssumptionsBlk)
        @lexer.pop(NexusParser::Tokens::AssumptionsBlk)

      elsif @lexer.peek(NexusParser::Tokens::CodonsBlk)
        @lexer.pop(NexusParser::Tokens::CodonsBlk)
      end
      
    end
  end

  # just removes it for the time being
  def parse_authors_blk
    # thing has non single word key/value pairs, like "AUTHOR NAME", SIGH
    # for now just slurp it all up.
    @lexer.pop(NexusParser::Tokens::AuthorsBlk )

    #while true
    #  if @lexer.peek(NexusParser::Tokens::EndBlk)
    #    @lexer.pop(NexusParser::Tokens::EndBlk)
    #    break
    #  else

     #   while @lexer.peek(NexusParser::Tokens::ValuePair)
     #     # IMPORTANT, these are going to a general hash, there may ultimately be overlap of keys used in different blocks, this is ignored at present
     #     @builder.add_var(@lexer.pop(NexusParser::Tokens::ValuePair).value) 
     #   end
        
        #@lexer.pop(NexusParser::Tokens::ID) if @lexer.peek(NexusParser::Tokens::ID)
     # end
    #end
  end

  def parse_taxa_blk 
    @lexer.pop(NexusParser::Tokens::Title) if @lexer.peek(NexusParser::Tokens::Title)

    # need to not ignore to test against
    parse_dimensions if @lexer.peek(NexusParser::Tokens::Dimensions)

    inf = 0
    while true
      inf += 1
      raise(NexusParser::ParseError,"Either you have a gazillion taxa or more likely the parser is caught in an infinite loop trying to parser taxon labels. Check for double single quotes in this block.") if inf > 100000
    
      if @lexer.peek(NexusParser::Tokens::EndBlk)
        @lexer.pop(NexusParser::Tokens::EndBlk)
        break
      else

        if @lexer.peek(NexusParser::Tokens::Taxlabels)
          @lexer.pop(NexusParser::Tokens::Taxlabels) if @lexer.peek(NexusParser::Tokens::Taxlabels)
          i = 0
          while @lexer.peek(NexusParser::Tokens::Label)
            @builder.update_taxon(:index => i, :name => @lexer.pop(NexusParser::Tokens::Label).value) 
            i += 1
          end 
          @lexer.pop(NexusParser::Tokens::SemiColon) if @lexer.peek(NexusParser::Tokens::SemiColon) # close of tax labels, placement of this seems dubious... but tests are working
        
        elsif  @lexer.peek(NexusParser::Tokens::MesquiteIDs)

          @lexer.pop(NexusParser::Tokens::MesquiteIDs) # trashing these for now
        elsif  @lexer.peek(NexusParser::Tokens::MesquiteBlockID)
          @lexer.pop(NexusParser::Tokens::MesquiteBlockID) 
        end
        
      end
    end


  end

  def parse_characters_blk 
    
    inf = 0 
    while true
      inf += 1
      raise(NexusParser::ParseError,"Either you have a gazillion characters or more likely the parser is caught in an infinite loop trying to parser character data. Check for double single quotes in this block.") if inf > 100000

      if @lexer.peek(NexusParser::Tokens::EndBlk) # we're at the end of the block, exit after geting rid of the semi-colon
        break 
      else
        @lexer.pop(NexusParser::Tokens::Title) if @lexer.peek(NexusParser::Tokens::Title) # not used at present
        @lexer.pop(NexusParser::Tokens::LinkLine) if @lexer.peek(NexusParser::Tokens::LinkLine) # trashing these for now
        
        parse_dimensions if @lexer.peek(NexusParser::Tokens::Dimensions)
        parse_format if @lexer.peek(NexusParser::Tokens::Format) 
        
        parse_chr_state_labels if @lexer.peek(NexusParser::Tokens::CharStateLabels)

        parse_matrix if @lexer.peek(NexusParser::Tokens::Matrix) 
    
        # handle "\s*OPTIONS MSTAXA = UNCERTAIN;\s\n" within a characters block (sticks in an infinite loop right now)


        @lexer.pop(NexusParser::Tokens::MesquiteIDs) if @lexer.peek(NexusParser::Tokens::MesquiteIDs) # trashing these for now
        @lexer.pop(NexusParser::Tokens::MesquiteBlockID) if @lexer.peek(NexusParser::Tokens::MesquiteBlockID) # trashing these for now
    
        false
      end
    end
    @lexer.pop(NexusParser::Tokens::EndBlk)
  end

  # prolly pop header then fuse with parse_dimensions
  def parse_format
    @lexer.pop(NexusParser::Tokens::Format) 

    while @lexer.peek(NexusParser::Tokens::ValuePair) || @lexer.peek(NexusParser::Tokens::RespectCase)
      @lexer.pop(NexusParser::Tokens::RespectCase) if @lexer.peek(NexusParser::Tokens::RespectCase) # !! TODO: nothing is set, respect case is ignored
      @builder.add_var(@lexer.pop(NexusParser::Tokens::ValuePair).value) if @lexer.peek(NexusParser::Tokens::ValuePair)
    end

    check_initialization_of_ntax_nchar
  end

  def parse_dimensions  
    @lexer.pop(NexusParser::Tokens::Dimensions)
    while @lexer.peek(NexusParser::Tokens::ValuePair)
      @builder.add_var(@lexer.pop(NexusParser::Tokens::ValuePair).value)
    end
    # the last value pair with a ; is automagically handled, don't try popping it again
    
    check_initialization_of_ntax_nchar
  end

  def check_initialization_of_ntax_nchar
    # check for character dimensions, if otherwise not set generate them
    if @builder.nexus_file.vars[:nchar] && @builder.nexus_file.characters == []
      (0..(@builder.nexus_file.vars[:nchar].to_i - 1)).each {|i| @builder.stub_chr }
    end
    
    # check for taxa dimensions, if otherwise not set generate them
    if @builder.nexus_file.vars[:ntax] && @builder.nexus_file.taxa == []
      (0..(@builder.nexus_file.vars[:ntax].to_i - 1)).each {|i| @builder.stub_taxon }
    end
  end

  def parse_chr_state_labels
    @lexer.pop(NexusParser::Tokens::CharStateLabels)
 
    inf = 0 
    while true
      inf += 1
      raise(NexusParser::ParseError,"Either you have a gazillion character state labels or more likely the parser is caught in an infinite loop while trying to parser character state labels. Check for double single quotes in this block.") if inf > 100000

      if @lexer.peek(NexusParser::Tokens::SemiColon)    
        break 
      else
        opts = {}
        
        name = ""
        index = @lexer.pop(NexusParser::Tokens::Number).value.to_i
        (name = @lexer.pop(NexusParser::Tokens::Label).value) if @lexer.peek(NexusParser::Tokens::Label) # not always given a letter

        @lexer.pop(NexusParser::Tokens::BckSlash) if @lexer.peek(NexusParser::Tokens::BckSlash)

        if !@lexer.peek(NexusParser::Tokens::Comma) || !@lexer.peek(NexusParser::Tokens::SemiColon)
          i = 0

          # three kludge lines, need to figure out the label/number priority, could be issue in list order w/in tokens
          while @lexer.peek(NexusParser::Tokens::Label) || @lexer.peek(NexusParser::Tokens::Number)
            opts.update({i.to_s => @lexer.pop(NexusParser::Tokens::Label).value}) if @lexer.peek(NexusParser::Tokens::Label)
            opts.update({i.to_s => @lexer.pop(NexusParser::Tokens::Number).value.to_s}) if @lexer.peek(NexusParser::Tokens::Number)

            i += 1
          end  
        end

        @lexer.pop(NexusParser::Tokens::Comma) if @lexer.peek(NexusParser::Tokens::Comma) # we may also have hit semicolon
        
        opts.update({:index => (index - 1), :name => name})
       
        raise(NexusParser::ParseError, "Error parsing character state labels for (or around) character #{index - 1}.") if !opts[:name]
        @builder.update_chr(opts)
      end     

    end
    @lexer.pop(NexusParser::Tokens::SemiColon) 
  end

  def parse_matrix
    @lexer.pop(NexusParser::Tokens::Matrix)
    i = 0
      while true
        if @lexer.peek(NexusParser::Tokens::SemiColon)
         break 
        else
          t = @lexer.pop(NexusParser::Tokens::Label).value

          @builder.update_taxon(:index => i, :name => t) # if it exists its not re-added

          @builder.code_row(i, @lexer.pop(NexusParser::Tokens::RowVec).value)
      
          i += 1
        end
      end
    @lexer.pop(NexusParser::Tokens::SemiColon) # pop the semicolon 
  end

  # this suck(s/ed), it needs work when a better API for Mesquite comes out
  def parse_notes_blk
    # IMPORTANT - we don't parse the (CM <note>), we just strip the "(CM" ... ")" bit for now in NexusParser::Note

    @vars = {} 
    inf = 0 # a crude iteration checker
    while true
      inf += 1
      raise(NexusParser::ParseError,"Either you have a gazillion notes or more likely parser is caught in an infinite loop inside the Begin Notes block.  Check for double single quotes in this block.") if inf > 100000
      if @lexer.peek(NexusParser::Tokens::EndBlk)
        @lexer.pop(NexusParser::Tokens::EndBlk)
        @builder.add_note(@vars) # one still left to add
        break
      else

        if @lexer.peek(NexusParser::Tokens::ValuePair)
          @vars.update(@lexer.pop(NexusParser::Tokens::ValuePair).value)
      
        elsif @lexer.peek(NexusParser::Tokens::Label)
          if @vars[:type] # we have the data for this row write it, and start a new one    
            
            @builder.add_note(@vars)
            @vars = {}
          else
            @vars.update(:type => @lexer.pop(NexusParser::Tokens::Label).value)
          end
        elsif @lexer.peek(NexusParser::Tokens::FileLbl)  
          @lexer.pop(NexusParser::Tokens::FileLbl)
          @vars.update(:file => 'file') # we check for whether :file key is present and handle conditionally
        end
      end
    end
  end

    #@vars = {}
    #while true
      
    #  break if  @lexer.peek(NexusParser::Tokens::EndBlk)   
      
    #  @vars.update(:type => @lexer.pop(NexusParser::Tokens::Label).value)

      # kludge to get around the funny construct that references file
     # if @lexer.peek(NexusParser::Tokens::FileLbl)
    #    @lexer.pop(NexusParser::Tokens::FileLbl)
    #      vars.update(:file => 'file') # we check for whether :file key is present and handle conditionally
     #   end

     #   while true

     #     meh = @lexer.pop(NexusParser::Tokens::ValuePair)          
     #     @vars.update(meh.value)
     #     break if !@lexer.peek(NexusParser::Tokens::ValuePair)
     #   end
     #   
     #   @builder.add_note(@vars)
     #   @vars = {}
    #end
   # @lexer.pop(NexusParser::Tokens::EndBlk)


  def parse_trees_blk
    true
  end

  def parse_labels_blk

  end

  def parse_sets_blk
  end

  def parse_assumptions_blk
  end

  def parse_codens_blk
    # not likely
  end

  def parse_mesquitecharmodels_blk
    # nor this
  end

  
  def parse_mesquite_blk

  end



  # def parse_children(parent)
  # parse a comma-separated list of nodes
  #  while true 
  #    parse_node(parent)
  #    if @lexer.peek(NexusParser::Tokens::Comma)
  #      @lexer.pop(NexusParser::Tokens::Comma)
  #    else
  #      break
  #    end
  #  end
  # end
  
end



