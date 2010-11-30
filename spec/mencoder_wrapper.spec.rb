require File.dirname(__FILE__) + "/common"
require_relative '../lib/mencoder_wrapper'

describe MencoderWrapper do

  before do
    @a = YAML.load_file "../zamples/edit_decision_lists/dvds/happy_feet.txt"
    @out = MencoderWrapper.get_bat_commands @a, "e:\\", 'to_here'
  end
  
  it "should be able to convert" do      
    @out.should_not be nil
    @out.should include("e:\\")
  end
  
  it "should use newline every line" do
    @out.should include("\n")
    @out.should_not match(/mencoder.*mencoder/)
    @out.should_not match(/del.*del/)
  end
  
  it "should use start and stop times" do
    @out.should include(" -ss ")
    @out.should include(" -endpos ")
  end
  
  it "should have what looks like a working mencoder command" do
    @out.should include("-ovc copy")
    @out.should include("-oac copy")
  end
  
  it "should accomodate for mutes" do
    @out.should match(/ -nosound/)
  end
  
  it "should use avi extension" do
    @out.should include(".avi ")
  end
  
  it "should concatenate them all together" do
    @out.should match(/mencoder.*\*.*ovc.*oac/)
  end
  
  it "should delete any large, grabbed tmp file" do
    @out.should match(/del.*tmp/)
  end
  
  it "should delete any partials" do
    0.upto(5) do |n|
      @out.should match(Regexp.new(/del.*#{n}/))
    end
  end
  
  def setup
    settings = {"mutes"=>{1=>2, 7=>12}, "blank_outs"=>{"2"=>"3"}}
    @out = MencoderWrapper.get_bat_commands settings, "e:\\", 'to_here.avi'
  end
  
  it "should not insert an extra pause if a mute becomes a blank" do
    setup
    @out.should_not match(/-endpos 0.0/)
    print @out
    File.write('out.bat', @out)
  end
  
  it "should avoid blanks" do
    setup
    @out.should_not include('-ss 2.0 -endpos 1.0')
    # and not be freaky
    @out.should_not match(/-endpos \d{6}.*nosound/)
  end
  
  it "should lop off a fraction of a second" do
    setup
    @out.should match(/-endpos 0.999/)
  end
  
  it "should not have doubles" do
    setup  
    @out.scan(/-endpos.*-o to_here.avi.avi.1/).length.should == 1
    @out.scan(/-endpos.*-o to_here.avi.avi.2/).length.should == 1
  end
  
end