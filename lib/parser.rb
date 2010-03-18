
class NexusFile::Parser
 
  def initialize(lexer, builder)
    @lexer = lexer
    @builder = builder
  end

  def parse_file
    # nf = @builder.new_nexus_file # create new local NexusFile instance, nf
    blks = []
    @lexer.pop(NexusFile::Tokens::NexusStart)
     
    while @lexer.peek(NexusFile::Tokens::BeginBlk)
       
      @lexer.pop(NexusFile::Tokens::BeginBlk) # pop it
      
      if @lexer.peek(NexusFile::Tokens::AuthorsBlk)
        parse_authors_blk
        
      # we parse these below 
      elsif @lexer.peek(NexusFile::Tokens::TaxaBlk)
        
        @lexer.pop(NexusFile::Tokens::TaxaBlk )
        parse_taxa_blk
           
      elsif @lexer.peek(NexusFile::Tokens::ChrsBlk)
        @lexer.pop(NexusFile::Tokens::ChrsBlk)
        parse_characters_blk

      elsif @lexer.peek(NexusFile::Tokens::NotesBlk)
        @lexer.pop(NexusFile::Tokens::NotesBlk)  
        parse_notes_blk

      # we should parse this
      elsif @lexer.peek(NexusFile::Tokens::SetsBlk)
        @lexer.pop(NexusFile::Tokens::SetsBlk)

      # we don't parse these 
      elsif @lexer.peek(NexusFile::Tokens::TreesBlk)
        @foo =  @lexer.pop(NexusFile::Tokens::TreesBlk).value
 
      elsif @lexer.peek(NexusFile::Tokens::LabelsBlk)
        @lexer.pop(NexusFile::Tokens::LabelsBlk)
   
      elsif @lexer.peek(NexusFile::Tokens::MqCharModelsBlk)
        @lexer.pop(NexusFile::Tokens::MqCharModelsBlk) 

      elsif @lexer.peek(NexusFile::Tokens::AssumptionsBlk)
        @lexer.pop(NexusFile::Tokens::AssumptionsBlk)

      elsif @lexer.peek(NexusFile::Tokens::CodonsBlk)
        @lexer.pop(NexusFile::Tokens::CodonsBlk)
      end
      
    end
  end

  # just removes it for the time being
  def parse_authors_blk
    # thing has non single word key/value pairs, like "AUTHOR NAME", SIGH
    # for now just slurp it all up.
    @lexer.pop(NexusFile::Tokens::AuthorsBlk )

    #while true
    #  if @lexer.peek(NexusFile::Tokens::EndBlk)
    #    @lexer.pop(NexusFile::Tokens::EndBlk)
    #    break
    #  else

     #   while @lexer.peek(NexusFile::Tokens::ValuePair)
     #     # IMPORTANT, these are going to a general hash, there may ultimately be overlap of keys used in different blocks, this is ignored at present
     #     @builder.add_var(@lexer.pop(NexusFile::Tokens::ValuePair).value) 
     #   end
        
        #@lexer.pop(NexusFile::Tokens::ID) if @lexer.peek(NexusFile::Tokens::ID)
     # end
    #end
  end

  def parse_taxa_blk 
    @lexer.pop(NexusFile::Tokens::Title) if @lexer.peek(NexusFile::Tokens::Title)

    # need to not ignore to test against
    parse_dimensions if @lexer.peek(NexusFile::Tokens::Dimensions)

    while true
      if @lexer.peek(NexusFile::Tokens::EndBlk)
        @lexer.pop(NexusFile::Tokens::EndBlk)
        break
      else

        if @lexer.peek(NexusFile::Tokens::Taxlabels)
          @lexer.pop(NexusFile::Tokens::Taxlabels) if @lexer.peek(NexusFile::Tokens::Taxlabels)
          i = 0
          while @lexer.peek(NexusFile::Tokens::Label)
            @builder.update_taxon(:index => i, :name => @lexer.pop(NexusFile::Tokens::Label).value) 
            i += 1
          end 
          @lexer.pop(NexusFile::Tokens::SemiColon) if @lexer.peek(NexusFile::Tokens::SemiColon) # close of tax labels, placement of this seems dubious... but tests are working
        
        elsif  @lexer.peek(NexusFile::Tokens::MesquiteIDs)

          @lexer.pop(NexusFile::Tokens::MesquiteIDs) # trashing these for now
        elsif  @lexer.peek(NexusFile::Tokens::MesquiteBlockID)
          @lexer.pop(NexusFile::Tokens::MesquiteBlockID) 
        end
        
      end
    end


  end

  def parse_characters_blk 
    while true
      if @lexer.peek(NexusFile::Tokens::EndBlk) # we're at the end of the block, exit after geting rid of the semi-colon
        break 
      else
        @lexer.pop(NexusFile::Tokens::Title) if @lexer.peek(NexusFile::Tokens::Title) # not used at present

        parse_dimensions if @lexer.peek(NexusFile::Tokens::Dimensions)
        parse_format if @lexer.peek(NexusFile::Tokens::Format) 
        
        parse_chr_state_labels if @lexer.peek(NexusFile::Tokens::CharStateLabels)

        parse_matrix if @lexer.peek(NexusFile::Tokens::Matrix) 
    
        # handle "\s*OPTIONS MSTAXA = UNCERTAIN;\s\n" within a characters block (sticks in an infinite loop right now)

        @lexer.pop(NexusFile::Tokens::MesquiteIDs) if @lexer.peek(NexusFile::Tokens::MesquiteIDs) # trashing these for now
        @lexer.pop(NexusFile::Tokens::MesquiteBlockID) if @lexer.peek(NexusFile::Tokens::MesquiteBlockID) # trashing these for now
    
        false
      end
    end
    @lexer.pop(NexusFile::Tokens::EndBlk)
  end

  # prolly pop header then fuse with parse_dimensions
  def parse_format
    @lexer.pop(NexusFile::Tokens::Format) 
    while @lexer.peek(NexusFile::Tokens::ValuePair)
      @builder.add_var(@lexer.pop(NexusFile::Tokens::ValuePair).value)
    end

    check_initialization_of_ntax_nchar
  end

  def parse_dimensions  
    @lexer.pop(NexusFile::Tokens::Dimensions)
    while @lexer.peek(NexusFile::Tokens::ValuePair)
      @builder.add_var(@lexer.pop(NexusFile::Tokens::ValuePair).value)
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
    @lexer.pop(NexusFile::Tokens::CharStateLabels)
  
    while true
      if @lexer.peek(NexusFile::Tokens::SemiColon)    
        break 
      else
        opts = {}
        
        name = ""
        index = @lexer.pop(NexusFile::Tokens::Number).value.to_i
        (name = @lexer.pop(NexusFile::Tokens::Label).value) if @lexer.peek(NexusFile::Tokens::Label) # not always given a letter

        @lexer.pop(NexusFile::Tokens::BckSlash) if @lexer.peek(NexusFile::Tokens::BckSlash)

        if !@lexer.peek(NexusFile::Tokens::Comma) || !@lexer.peek(NexusFile::Tokens::SemiColon)
          i = 0

          # three kludge lines, need to figure out the label/number priority, could be issue in list order w/in tokens
          while @lexer.peek(NexusFile::Tokens::Label) || @lexer.peek(NexusFile::Tokens::Number)
            opts.update({i.to_s => @lexer.pop(NexusFile::Tokens::Label).value}) if @lexer.peek(NexusFile::Tokens::Label)
            opts.update({i.to_s => @lexer.pop(NexusFile::Tokens::Number).value.to_s}) if @lexer.peek(NexusFile::Tokens::Number)

            i += 1
          end  
        end

        @lexer.pop(NexusFile::Tokens::Comma) if @lexer.peek(NexusFile::Tokens::Comma) # we may also have hit semicolon
        
        opts.update({:index => (index - 1), :name => name})
       
        raise(ParserError, "Error parsing character state labels for (or around) character #{index -1}.") if !opts[:name]
        @builder.update_chr(opts)
      end     

    end
    @lexer.pop(NexusFile::Tokens::SemiColon) 
  end

  def parse_matrix
    @lexer.pop(NexusFile::Tokens::Matrix)
    i = 0
      while true
        if @lexer.peek(NexusFile::Tokens::SemiColon)
         break 
        else
          t = @lexer.pop(NexusFile::Tokens::Label).value

          @builder.update_taxon(:index => i, :name => t) # if it exists its not re-added

          @builder.code_row(i, @lexer.pop(NexusFile::Tokens::RowVec).value)
      
          i += 1
        end
      end
    @lexer.pop(NexusFile::Tokens::SemiColon) # pop the semicolon 
  end

  # this suck(s/ed), it needs work when a better API for Mesquite comes out
  def parse_notes_blk
    # IMPORTANT - we don't parse the (CM <note>), we just strip the "(CM" ... ")" bit for now in NexusFile::Note

    @vars = {} 
    inf = 0
    while true
      inf += 1
      raise "Either you have a gazillion notes or more likely parser is caught in an infinite loop inside parse_notes_block" if inf > 100000
      if @lexer.peek(NexusFile::Tokens::EndBlk)
        @lexer.pop(NexusFile::Tokens::EndBlk)
        @builder.add_note(@vars) # one still left to add
        break
      else

        if @lexer.peek(NexusFile::Tokens::ValuePair)
          @vars.update(@lexer.pop(NexusFile::Tokens::ValuePair).value)
      
        elsif @lexer.peek(NexusFile::Tokens::Label)
          if @vars[:type] # we have the data for this row write it, and start a new one    
            
            @builder.add_note(@vars)
            @vars = {}
          else
            @vars.update(:type => @lexer.pop(NexusFile::Tokens::Label).value)
          end
        elsif @lexer.peek(NexusFile::Tokens::FileLbl)  
          @lexer.pop(NexusFile::Tokens::FileLbl)
          @vars.update(:file => 'file') # we check for whether :file key is present and handle conditionally
        end
      end
    end
  end

    #@vars = {}
    #while true
      
    #  break if  @lexer.peek(NexusFile::Tokens::EndBlk)   
      
    #  @vars.update(:type => @lexer.pop(NexusFile::Tokens::Label).value)

      # kludge to get around the funny construct that references file
     # if @lexer.peek(NexusFile::Tokens::FileLbl)
    #    @lexer.pop(NexusFile::Tokens::FileLbl)
    #      vars.update(:file => 'file') # we check for whether :file key is present and handle conditionally
     #   end

     #   while true

     #     meh = @lexer.pop(NexusFile::Tokens::ValuePair)          
     #     @vars.update(meh.value)
     #     break if !@lexer.peek(NexusFile::Tokens::ValuePair)
     #   end
     #   
     #   @builder.add_note(@vars)
     #   @vars = {}
    #end
   # @lexer.pop(NexusFile::Tokens::EndBlk)


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
  #    if @lexer.peek(NexusFile::Tokens::Comma)
  #      @lexer.pop(NexusFile::Tokens::Comma)
  #    else
  #      break
  #    end
  #  end
  # end
  
end



