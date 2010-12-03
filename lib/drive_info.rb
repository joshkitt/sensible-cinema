require 'digest/md5'
require 'ruby-wmi'

class DriveInfo

 def self.md5sum_disk(dir)
  digest = Digest::MD5.new()
  
  Dir[dir + "VIDEO_TS/*.IFO"].sort.each{|f|
    digest << File.binread(f) 
  }
  digest.hexdigest
 end

 def self.get_dvd_drives_as_win32ole
   disks = WMI::Win32_LogicalDisk.find(:all)
   disks.select{|d| d.Description =~ /CD-ROM/} # hope this works...
 end
  
def self.get_drive_with_most_space_with_slash
  disks = WMI::Win32_LogicalDisk.find(:all)
  most_space = disks.sort_by{|d| d.FreeSpace.to_i}[-1]
  most_space.Name + "\\"
end

end
