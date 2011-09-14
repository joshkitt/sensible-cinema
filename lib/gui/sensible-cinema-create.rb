module SensibleSwing
  
  class MainWindow

    def setup_advanced_buttons
    
      new_jbutton("Display the standard buttons") do
        window = new_child_window
        window.setup_normal_buttons
      end
      
      @mplayer_edl = new_jbutton( "Watch DVD edited (realtime) (mplayer)")
      @mplayer_edl.on_clicked {
        play_mplayer_edl_non_blocking nil, [], true, false
      }
    
      add_text_line 'Realtime/Create Options:'
      
      @create_new_edl_for_current_dvd = new_jbutton("Create new Edit List for a DVD", 
        "If your DVD doesn't have an EDL created for it, this will be your first step--create an EDL file for it.")
      @create_new_edl_for_current_dvd.on_clicked do
        create_brand_new_edl
        @display_dvd_info.simulate_click # for now...
      end
      
      @open_list = new_jbutton("Open/Edit a previously created Edit List file", "If your DVD has a previously existing EDL for it, you can open it to edit it with this button.")
      @open_list.on_clicked {
        filename = new_existing_file_selector_and_select_file( "Pick any file to open in editor", EdlParser::EDL_DIR)
        open_file_to_edit_it filename
      }
      
      @play_smplayer = new_jbutton( "Watch full DVD unedited (realtime smplayer)")
      @play_smplayer.tool_tip = <<-EOL
        This will play the DVD unedited within smplayer.
        NB it will default to title 1, so updated your EDL file that matches this DVD with the proper title if this doesn't work for you 
        i.e. if it just plays a single preview title or what not, and not the main title, you need to change this value.
        This is useful if you want to just kind of watch the movie to enjoy it, and look for scenes to cut out.
        You can use the built-in OSD (on-screen-display) to see what time frame the questionable scenes are at
        (type "o" to toggle it).  However, just realize that the OSD is in 30 fps, and our time stamps are all in 29.97
        fps, so you'll need to convert it (the convert timestamp button) to be able to use it in a file.
      EOL
      @play_smplayer.on_clicked {
        play_dvd_smplayer_unedited false, true, true
      }

      @play_mplayer_raw = new_jbutton( "Watch full DVD unedited (realtime mplayer)")
      @play_mplayer_raw.tool_tip = <<-EOL
        This is also useful for comparing subtitle files to see if they have accurate timings.
        If you turn on subtitles (use the v button), then compare your srt file at say, the 1 hour mark, or 2 hour mark,
        with the subtitles that mplayer displays, it *should* match exactly with the output in the command line,
        like "V: 3600.0" should match your subtitle line "01:00:00,000 --> ..."
      EOL
      @play_mplayer_raw.on_clicked {
        play_dvd_smplayer_unedited true, true, true
      }
      
      @parse_srt = new_jbutton("Scan a subtitle file (.srt) to detect profanity times automatically" )
      @parse_srt.tool_tip = <<-EOL
        You can download a .srt file and use it to automatically search for profanities.
        Basically download it from opensubtitles.org (possibly from other sites, too),
        (enter dvd name in the search box, click a result, click one from the list with an English flag, then click 'Download(zip)')
        Once you download the zip, unzip it, and then compare the timestamps in it with those on the DVD (see the button "Watch DVD unedited (realtime mplayer)")
        NB that you'll first want/need to *carefully* double check your subtitle
        file with the actual DVD.  (ex: smplayer, hit the 'o' button to display
        the current timestamp, then go to the end, stop at some point with text
        and hit the '.' key until a subtitle very first displays.
        Next convert that number to 29.97 fps (using the button given).
        The numbers should match precisely.  If they don't, edit this file
        so that it will have some offsets given.
      EOL

      @parse_srt.on_clicked do
        filename = new_existing_file_selector_and_select_file("Pick srt file to scan for profanity:")
        add_to_beginning = get_user_input("How much time to subtract from the beginning of every subtitle entry (ex: (1:00,1:01) becomes (0:59,1:01))", "0.0")
        add_to_end = get_user_input("How much time to add to the end of every subtitle entry (ex: (1:00,1:04) becomes (1:00,1:05))", "0.0")
        start_srt = get_user_input("timestamp of init srt", "00:00")
        start_movie_ts = get_user_input("timestamp of initial subtitle in movie itself", "00:00")
        end_srt = get_user_input("timestamp of near end subtitle srt", "10:00:00")
        end_movie_ts  = get_user_input("timestamp of near end subtitle in movie itself", "10:00:00")
        parsed = SubtitleProfanityFinder.edl_output filename, {}, add_to_beginning.to_f, add_to_end.to_f, start_srt, start_movie_ts, end_srt, end_movie_ts
        File.write(EdlTempFile, "# add these into your mute section if you deem them mute-worthy\n" + parsed)
        open_file_to_edit_it filename, true
        sleep 0.3 if OS.mac? # add delay...
        open_file_to_edit_it EdlTempFile
      end

      @display_dvd_info = new_jbutton( "Display information about current DVD (ID, etc.)" )
      @display_dvd_info.tool_tip = "This is useful to setup a DVD's 'unique ID' within an EDL for it. \nIf your EDL doesn't have a line like disk_unique_id => \"...\" then you will want to run this to be able to add that line in."
      @display_dvd_info.on_clicked {
        drive, volume_name, dvd_id = choose_dvd_drive_or_file true # real DVD disk
        # display it, allow them to copy and paste it out
        title_lengths = nil
        t = Thread.new { title_lengths= `mplayer dvdnav:// -nocache -dvd-device #{drive} -identify -frames 0 2>&1| grep LENGTH` }
        id_string = "\"disk_unique_id\" => \"#{dvd_id}\", # #{volume_name}"
        show_copy_pastable_string "#{drive} #{volume_name} for your copying+pasting pleasure (highlight, then ctrl+c to copy)\n
        This is USED eventually to identify a disk to match it to its EDL, later.", id_string
        t.join
        File.write EdlTempFile, id_string + "\n" + title_lengths
        open_file_to_edit_it EdlTempFile
        id_string
      }

      @convert_seconds_to_ts = new_jbutton( "Convert 3600.0 <-> 1:00:00 style timestamps" )
      @convert_seconds_to_ts.on_clicked {
        input = get_user_input("Enter \"from\" timestamps, like 3600 or 1:40:00:", "1:00:00.1 or 3600.1")
        while(input)
          if input =~ /:/
            output = EdlParser.translate_string_to_seconds input
          else
            output = EdlParser.translate_time_to_human_readable input.to_f, true
          end 
          input = show_copy_pastable_string("Converted:", output)         
        end
      }
      
      @convert_timestamp = new_jbutton( "Convert timestamp from DVD player time to EDL time (30->29.97 fps)" )
      @convert_timestamp.tool_tip=<<-EOL
        Our EDL's assume 29.97 fps (which is what a DVD actually has).  Unfortunately most hardware or commercial DVD players
        think that the DVD is 30 fps, which means that if you use them for timestamps for your EDL's,
        you will be slightly off (at the end of a 2 hour film, by 8 seconds).  So all your edits will be wrong.
        How to fix: convert your times from "DVD player" time to "EDL accurate" time by using this button.
        This is necessary for all hardware DVD player timestamps, PowerDVD player (software), Windows Media Player (playing a DVD), 
        and mplayer's "on screen display" DVD timestamps.
        It is not necessary for smplayer timestamps (or mplayer's "V: 3600" in the command line), which are already 29.97.
        smplayer's on-screen-display (the 'o' key) is accurate (and doesn't suffer from dvd_mplayer_splits) 
        but is 30 fps, so timestamps would need to be converted.
        Dont use VLC for DVD timestamps at all--it can get up to 30s off!  VLC playing back a file is usually pretty accurate to 29.97.
        In general, GUI's like VLC or smplayer are always a tidge off (maybe 0.3s) from the right timestamp, so take that into consideration.
        Mplayers "V: 3600" is usually right on (29.97 fps), however.
      EOL
      @convert_timestamp.on_clicked {
        thirty_fps = get_user_input("Enter your DVD (30 fps) timestamp, I'll convert it to 29.97 (usable in EDL's):", "1:00:00.1")
        thirty_fps_in_seconds = EdlParser.translate_string_to_seconds thirty_fps
        twenty_nine_seven_fps = ConvertThirtyFps.from_thirty(thirty_fps_in_seconds)
        human_twenty_nine_seven = EdlParser.translate_time_to_human_readable twenty_nine_seven_fps, true
        show_copy_pastable_string("Sensible cinema usable value (29.97 fps) for #{thirty_fps} would be:                ", human_twenty_nine_seven)
      }
      
      @create_dot_edl = new_jbutton( "Create a side-by-side moviefilename.edl file")
      @create_dot_edl.tool_tip = <<-EOL
        Creates a moviefilename.edl file (corresponding to some moviefilename.some_ext file already existing)
        XBMC/smplayer (smplayer can be used by WMC plugins, etc.) "automagically detect", 
        if it exists, and automatically use it .edl to show that file edited played back.
        If you use smplayer, note that you'll need to download the "lord mulder mplayer"
        version (which includes an updated version of mplayer that fixes some bugs in EDL playback)
      EOL
      @create_dot_edl.on_clicked {
        choose_file_and_edl_and_create_sxs_or_play true
      }
      
      add_text_line 'Create Options with local intermediary file:'
      
      new_jbutton("Show options with local intermediary file") do
        window = new_child_window
        window.add_options_that_use_local_files
      end
      
#      @reload = new_jbutton("reload bin/sensible-cinema code") do
#        load $0
#      end
      
    end # advanced buttons
    
    def add_options_that_use_local_files
      add_text_line 'Create Options that first create/use a local intermediary file:'

      @preview_section = new_jbutton( "Preview a certain time frame from fulli file (edited)" )
      @preview_section.tool_tip = <<-EOL
        This allows you to preview an edit easily.
        It is the equivalent of saying \"watch this file edited from exactly minute x second y to minute z second q"
        Typically if you want to test an edit, you can start a few seconds before, and end a few seconds after it, to test it precisely.
      EOL
      @preview_section.on_clicked {
        do_create_edited_copy_via_file true
      }
      
      @preview_section_unedited = new_jbutton("Preview a certain time frame from fulli file (unedited)" )
      @preview_section.tool_tip = "Allows you to view a certain time frame unedited (ex: 10:00 to 10:05), so you can narrow down to pinpoint where questionable scenes are, etc. This is the only way to view a specific scene if there are not cuts within that scene yet."
      @preview_section_unedited.on_clicked {
        do_create_edited_copy_via_file true, false, true
      }

      @rerun_preview = new_jbutton( "Re-run most recently watched preview time frame from fulli file" )
      @rerun_preview.tool_tip = "This will re-run the preview that you most recently performed.  Great for checking to see if you last edits were successful or not."
      @rerun_preview.on_clicked {
        repeat_last_copy_dvd_to_hard_drive
      }
      
      # Maybe this button should go too...
      @fast_preview = new_jbutton("fast preview all from fulli file (smplayer EDL)")
      @fast_preview.tool_tip = <<-EOL
        Plays smplayer on a file with an EDL.
        This gives you a rough estimate to see if your edits are accurate, and is really fast to seek, etc.
        This is useful because you can't use mplayer on a DVD for accurate timestamps if it has any 
        timestamp splits in it [because some DVD's are buggy]
      EOL
      @fast_preview.on_clicked {
        success, wrote_to_here_fulli = do_create_edited_copy_via_file false, true
        sleep 0.5 # lodo take out ???
        background_thread.join if background_thread # let it write out the original fulli, if necessary [?]
        nice_file = wrote_to_here_fulli
        run_smplayer_blocking nice_file, nil, "-edl #{normalize_path EdlTempFile}", false, true, false
      }
    end
    
    def do_create_edited_copy_via_file should_prompt_for_start_and_end_times, exit_early_if_fulli_exists = false, watch_unedited = false
      drive_or_file, dvd_volume_name, dvd_id, edit_list_path, descriptors = choose_dvd_or_file_and_edl_for_it
      
      descriptors = parse_edl(edit_list_path)
      if watch_unedited
        # reset them
        descriptors['mutes'] = descriptors['blank_outs'] = []
      end
      
      # LODO allow for spaces in the save_to filename
      if should_prompt_for_start_and_end_times
        # only show this message once :)
        @show_block ||= show_blocking_message_dialog(<<-EOL, "Preview")
          Ok, let's preview just a portion of it. 
          Note that you'll want to preview a section that wholly includes a deleted section in it.
          For example, if it mutes from second 1 to second 10, you'll want to play from 00:00 to 00:12 or what not.
          Also note that the first time you preview a section of a video, it will take a long time (like an hour) as it sets up the entire video for processing.
          Subsequent previews will be faster, though, as long as you use the same filename, as it won't have to re-set it up for processing.
          Also note that if you change your edit list, you'll need to close, and restart the video to be able to see it with your new settings.
        EOL
        old_start = LocalStorage['start_time']
        start_time = get_user_input("At what point in the video would you like to start your preview? (like 01:00 for starting at 1 minute)", LocalStorage['start_time'])
        default_end = LocalStorage['end_time']
        if start_time and start_time != old_start
          default_end = EdlParser.translate_string_to_seconds(start_time) + 10
          default_end = EdlParser.translate_time_to_human_readable(default_end)
        end
        end_time = get_user_input("At what point in the video would you like to finish your preview? (like 02:00 for ending at the 2 minute mark)", default_end)
        unless start_time and end_time
          # this one is raw showMessageDialog...
          JOptionPane.showMessageDialog(nil, " Please choose start and end", "Failed", JOptionPane::ERROR_MESSAGE)
          return
        end
        LocalStorage['start_time'] = start_time
        LocalStorage['end_time'] = end_time
      end
      dvd_friendly_name = descriptors['name']
      unless dvd_friendly_name
        drive_or_file, dvd_volume_name, dvd_id, edit_list_path, descriptors = choose_dvd_or_file_and_edl_for_it
        descriptors = parse_edl(edit_list_path)
        raise 'no dvd name in EDL?' + edit_list_path + File.read(edit_list_path)
      end
      
      dvd_title_track = get_title_track(descriptors)
      if dvd_id == NonDvd
        file_from = drive_or_file
      else
        file_from = get_grabbed_equivalent_filename_once dvd_friendly_name, dvd_title_track # we don't even care about the drive letter anymore...
      end
      show_blocking_message_dialog("warning: file #{file_from} is not a .mpg or .ts file--it may not work properly all the way--if it's mkv and fails consider first converting to ts by using tsmuxer.") unless file_from =~ /\.(ts|mpg|mpeg)$/i
      save_to_edited = get_save_to_filename dvd_friendly_name
      fulli = MencoderWrapper.calculate_fulli_filename save_to_edited
      if exit_early_if_fulli_exists
        if fulli_dot_done_file_exists? save_to_edited
          return [true, fulli]
        end
        # make it create a dummy response file for us :)
        start_time = "00:00"
        end_time = "00:01"
      end
      should_run_mplayer = should_prompt_for_start_and_end_times || exit_early_if_fulli_exists
      require_deletion_entry = true unless watch_unedited
      generate_and_run_bat_file save_to_edited, edit_list_path, descriptors, file_from, dvd_friendly_name, start_time, end_time, dvd_title_track, should_run_mplayer, require_deletion_entry
      [false, fulli] # false means it's running in a background thread :P
    end
    
    def create_brand_new_edl
      drive, volume, dvd_id = choose_dvd_drive_or_file true
      english_name = get_user_input("Enter a human readable DVD description for #{volume}", volume.gsub('_', ' ').downcase)
      input = <<-EOL
# comments can go after a # on any line, for example this one.
"name" => "#{english_name}",

"mutes" => [
  # an example line, uncomment the leading "#" to make it active
  # "0:00:01.0", "0:00:02.0", "profanity", "da..", 
],

"blank_outs" => [
  # an example line, uncomment the leading "#" to make it active
  # "00:03:00.0" , "00:04:00.0", "violence", "of some sort",
],

"volume_name" => "#{volume}",
"disk_unique_id" => "#{dvd_id}",
"dvd_title_track" => "1", # the "show DVD info" button will tell you title lengths (typically longest title is the title track)
# "dvd_title_track_length" => "9999", # length, on the DVD, of dvd_title_track (use the show DVD info button to get this number).
# "subtitle_url" => "1234567",
# "not edited out stuff" => "some...",
# "closing thoughts" => "only...",
# In mplayer, the DVD timestamp "resets" to zero for some reason, so you need to specify when if you want to use mplayer DVD realtime playback, or use mencoder -edl to split your file.  See http://goo.gl/yMfqX
# "mplayer_dvd_splits" => ["59:59", "1:04:59"], # or [] if there are none.  Additive currently.  12345.6 ok. 
        EOL
      # TODO auto-ify above, move docs to a file in documentation.
      filename = EdlParser::EDL_DIR + "/edls_being_edited/" + english_name.gsub(' ', '_') + '.txt'
      filename.downcase!
      File.write(filename, input) unless File.exist?(filename) # lodo let them choose name (?)
      open_file_to_edit_it filename
    end     
    
    
  end
end