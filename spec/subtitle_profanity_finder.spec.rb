=begin
Copyright 2010, Roger Pack 
This file is part of Sensible Cinema.

    Sensible Cinema is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    Sensible Cinema is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with Sensible Cinema.  If not, see <http://www.gnu.org/licenses/>.
=end

require File.expand_path(File.dirname(__FILE__) + '/common')
require_relative '../lib/subtitle_profanity_finder'
require 'sane'

describe SubtitleProfanityFinder do

  describe "should parse out various profanities" do
    
    output = SubtitleProfanityFinder.edl_output ['dragon.srt']
    
    describe "heck" do
      it "should include the bad line with timestamp" do
        output.should match(/00:00:54.929.*"he\.\."/)
      end
    
      it "should include the description in its output" do
        output.should include("e he.. b")
      end
    end
    
    describe "deity ... " do
      it "should parse output plural deity" do
        output.should include("nordic [deity]s ")
      end
      
      it "should parse out deity singular and at very end" do
        output = SubtitleProfanityFinder.edl_output ['deity_end.srt']
        output.should include("fortress is our [deity]")
      end
      
      it "should parse out <i> et al " do
        output = SubtitleProfanityFinder.edl_output ['deity_end.srt']
        output.should_not include(" i ")
        output.should_not include("<i")
        output.should_not include("huntingand")
        output.should_not include("  ")
      end
      
    end
    
    describe 'arse' do
      it 'should not parse it if it\'s in other words' do
        output =  SubtitleProfanityFinder.edl_output ['arse.srt']
        output.should_not include "a..ume"
        output.should include "don't" # different issue...
      end    
    end
    
  end
  
  describe "it should take optional user params" do
    output = SubtitleProfanityFinder.edl_output ['dragon.srt', 'word', 'word']
    
    it "should parse out the word word" do
      output.should match(/00:00:50.089.*"word"/)
    end
    
    it "should parse out and replace with euphemism" do
      output = SubtitleProfanityFinder.edl_output ['dragon.srt', 'word', 'w...']
      output.should match(/00:00:50.089.*In a w\.\.\./)
    end
    
  end
  
end