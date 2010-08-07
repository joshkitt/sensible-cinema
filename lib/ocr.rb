im_path = File.expand_path(File.dirname(__FILE__) + "/../vendor/imagemagick") # convert.exe wants to only be chosen from here...
ENV['PATH'] = im_path + ';' + ENV['PATH']

require 'mini_magick'
require 'open3'

# helper for OCR'ing single digits that were screen captured
module OCR
  
  GOCR = File.expand_path(File.dirname(__FILE__) + "/../vendor/gocr048.exe -C 0-9:/ ")
  
  CACHE = {}
  
  # options are :might_be_colon, :should_invert
  def identify_digit memory_bitmap, options = {}
    if CACHE[memory_bitmap]
      return CACHE[memory_bitmap]
    else
    end
    might_be_colon = options[:might_be_colon]
    should_invert = options[:should_invert]
    if might_be_colon
      # do processing in-line <sigh>
      total = (memory_bitmap.scan /\x00{5}+/).length
      if total >= 3 # really should be 4 for VLC
        # it had some dots...must have been a colon!
      end
      CACHE[memory_bitmap] = ":"
      return ":"
    end
    image = MiniMagick::Image.from_blob(memory_bitmap)
    image.format(:pnm) # expensive, requires convert.exe in path...
    if should_invert # mogrify calls it negate...
      image.negate 
    end
    for level in [130, 100] # 100 for hulu...
      input, output, error, thread_if_on_19 = Open3.popen3 GOCR + " -l #{level} -"
      input.write image.to_blob
      input.close
      a = output.read
      output.close
      a.strip!
      if a =~ /[0-9]/
        a = a.to_i
        CACHE[memory_bitmap] = a
        return a
      end
    end
    nil
  end
  
  def version
    `#{GOCR} -h 2>&1`
  end
  
  extend self
  
end