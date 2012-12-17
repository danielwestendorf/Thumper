#
#  ThumperDelegate.rb
#  Thumper
#
#  Created by Daniel Westendorf on 4/2/11.
#  Copyright 2011 Daniel Westendorf. All rights reserved.
#

class NSIndexSet
    def each
        i = lastIndex
        while i != NSNotFound
            yield i
            i = indexLessThanIndex(i)
        end
    end
    
    include Enumerable
end


class ThumperDelegate
    attr_accessor :main_window, :status_label, :subsonic, :format_time
    attr_accessor :server_info_window, :server_url_field, :username_field, :password_field, :bitrate_field
    attr_accessor :server_url, :username, :password, :bitrate
    attr_accessor :artists, :all_artists, :artist_indexes_table_view, :artist_count_label, :artists_progress
    attr_accessor :albums, :albums_table_view, :album_count_label, :albums_progress
    attr_accessor :songs, :songs_table_view, :songs_count_label, :songs_progress
    attr_accessor :current_playlist, :current_playlist_table_view, :current_playlist_count_label
    attr_accessor :playing_song_object, :playing_song, :playing_song_object_progress
    attr_accessor :artist_reload_button, :album_reload_button, :song_reload_button
    attr_accessor :playlists, :playlists_table_view, :playlist_songs, :playlist_songs_table_view, :playlists_count_label, :playlist_songs_count_label
    attr_accessor :playlists_progress, :playlist_songs_progress, :playlist_songs_reload_button
	attr_accessor :playing_song_progress_view, :play_toggle_button, :play_previous_button, :play_next_button, :playing_cover_art, :playing_time_elapsed, :playing_time_remaining, :play_button, :volume_slider, :playing_title, :playing_info, :stop_button
    attr_accessor :playing_queue, :db_queue
    attr_accessor :mute_menu_item, :repeat_all_menu_item, :repeat_one_menu_item, :shuffle_menu_item
    attr_accessor :about_window
    attr_accessor :search_results
    attr_accessor :downloading_song
    attr_accessor :app_version
    attr_accessor :shuffle_button, :repeat_button
    attr_accessor :quick_playlists, :quick_playlists_table_view, :qp_offset
    attr_accessor :smart_playlists, :smart_playlists_table_view, :smart_playlist_add_button, :smart_playlist_remove_button, :smart_playlists_label
    attr_accessor :new_sp_window, :sp_name, :sp_genre, :sp_fromYear, :sp_toYear, :sp_size, :new_sp_save, :new_sp_cancel
    attr_accessor :t_update_window, :t_update_text, :t_update_button, :t_update_cancel_button
    attr_accessor :now_playing
    attr_accessor :downloading_enabled, :sharing_enabled, :rating_enabled
    attr_accessor :notification_queue
    attr_accessor :share_link_window, :share_link_close_button, :share_link_text_field
    attr_accessor :notification_view
    attr_accessor :current_music_folder
    attr_accessor :music_folders
    attr_accessor :main_menu, :status_item
    
    def initialize
        @quick_playlists = [["Random", "random"], ["Newest", "newest"], ["Highest Rated", "highest"], ["Most Frequent", "frequent"], ["Recently Played", "recent"]]
        @artists = []
        @albums = []
        @songs = []
        @now_playing = []
        @search_results = []
        @music_folders = []
        @movie_panels = []
        @current_music_folder = nil
        @qp_offset = 0
        @playlists = DB[:playlist_songs].group(:name).all.collect {|p| {:id => p[:playlist_id], :name => p[:name]} }
        @smart_playlists = DB[:smart_playlists].all.collect {|p|  p }
        @playing_queue = Dispatch::Queue.new('com.Thumper.playback')
        @db_queue = Dispatch::Queue.new('com.Thumper.db')
        @volume = 1.0
        @playlist_songs = []
        @shuffle = false
        @repeat_single = false
        @repeat_all = false
        @notification_queue = MRNotifier.new({:height => 100})
        @current_playlist = DB[:playlist_songs].join(:songs, :id => :song_id).filter(:playlist_id => '666current666').all
        @current_playlist.each {|s| s[:id] = s[:song_id]; s.delete(:song_id)}

        @server_url = NSUserDefaults.standardUserDefaults['thumper.com.server_url'] unless NSUserDefaults.standardUserDefaults['thumper.com.server_url'].nil?
        @username = NSUserDefaults.standardUserDefaults['thumper.com.username'] unless NSUserDefaults.standardUserDefaults['thumper.com.username'].nil?
        @password = NSUserDefaults.standardUserDefaults['thumper.com.password'] unless NSUserDefaults.standardUserDefaults['thumper.com.password'].nil?
        @bitrate = NSUserDefaults.standardUserDefaults['thumper.com.bitrate'].to_i unless NSUserDefaults.standardUserDefaults['thumper.com.bitrate'].nil?

        @current_server_url = @server_url
        
        p = []
        String.new(@password).each_byte{|c| p << sprintf("%02X", c)} if @password
        @enc_password = 'enc:' + p.join('') if @password
        
        NSNotificationCenter.defaultCenter.addObserver(self, selector:'playNext:', name:"ThumperNextTrack", object:nil)
        NSNotificationCenter.defaultCenter.addObserver(self, selector:'playPrevious:', name:"ThumperPreviousTrack", object:nil)
        NSNotificationCenter.defaultCenter.addObserver(self, selector:'playToggle:', name:"ThumperPlayToggle", object:nil)
        NSNotificationCenter.defaultCenter.addObserver(self, selector:'volumeUp:', name:"ThumperVolumeUp", object:nil)
        NSNotificationCenter.defaultCenter.addObserver(self, selector:'volumeDown:', name:"ThumperVolumeDown", object:nil)
        NSNotificationCenter.defaultCenter.addObserver(self, selector:'windowFront:', name:"ThumperWindowFront", object:nil)
        
        @now_playing_timer = NSTimer.scheduledTimerWithTimeInterval 5,
            target: self,
            selector: 'get_now_playing:',
            userInfo: nil,
            repeats: true
        
        #setup remote
        #ThumperRemoteListener.alloc.init
        @settings = NSUserDefaultsController.sharedUserDefaultsController
        @settings.setInitialValues({'volume' => 1.0})
    end
    
    def sendEvent(theEvent)
        shouldHandleMediaKeyEventLocally = !SPMediaKeyTap.usesGlobalMediaKeyTap
        if shouldHandleMediaKeyEventLocally && theEvent == NSSystemDefined && theEvent.subtype == SPSystemDefinedEventMediaKeys
            self.delegate(mediaKeyTap:nil, recievedMediaKeyEvent:theEvent)
        end
    end
    
    def get_now_playing(timer)
        @subsonic.get_now_playing(@subsonic, :now_playing_response) if @subsonic
    end
    
    def show_all_now_playing(sender)
        @subsonic.show_all_now_playing
    end
    
    def build_music_folder_menu
        folder_menu = @main_menu.itemWithTitle("Music Folders")#find the folder if it is already there
        
        if @music_folders.length > 1
            folder_menu = NSMenuItem.alloc.initWithTitle("Music Folders", action:nil, keyEquivalent:"") unless folder_menu
            folder_sub = NSMenu.alloc.initWithTitle("Music Folders")
            @music_folders.each do |folder|
                item = NSMenuItem.alloc.initWithTitle(folder[:name], action:"folder_selected:", keyEquivalent:"")
                item.setRepresentedObject(folder)
                @current_music_folder == folder[:id] ? item.setState(NSOnState) : item.setState(NSOffState)
                folder_sub.addItem(item) 
            end
            
            folder_sub.addItem(NSMenuItem.separatorItem)
            all = NSMenuItem.alloc.initWithTitle("All Folders", action:"folder_selected:", keyEquivalent:"")
            @current_music_folder == nil ? all.setState(NSOnState) : all.setState(NSOffState)
            folder_sub.addItem(all)
            
            folder_menu.setSubmenu(folder_sub)
            @main_menu.insertItem(folder_menu, atIndex:2) unless @main_menu.itemWithTitle("Music Folders")
        end
        #@current_music_folder = 1
        #get_artist_indexes
    end
    
    def folder_selected(sender)
        folder = sender.representedObject
        folder.nil? ? @current_music_folder = nil : @current_music_folder = folder[:id]
        
        build_music_folder_menu
        get_artist_indexes
    end
    
    def get_server_ip
       @playing_queue.sync do
            subdomain = @server_url.split('.').first.split('/').last
           #NSLog "Subdomain #{subdomain}"
            url = NSURL.URLWithString("http://subsonic.org/backend/redirect/get.view?redirectFrom=#{subdomain}")
            request = NSMutableURLRequest.requestWithURL(url, cachePolicy:NSURLRequestReloadIgnoringCacheData, timeoutInterval:60.0)
            response = String.new(NSURLConnection.sendSynchronousRequest(request, returningResponse:nil, error:nil)).split(' ').first
            response[response.length - 1] = ""
           #NSLog "Connecting to Subsonic Server via #{response}"
           @current_server_url = response
        end
    end
    
    def demo_close(sender)
        exit
    end
    
    def show_about(sender)
        @about_window.makeKeyAndOrderFront(nil)
        return true
    end
    
    def mediaKeyTap(keytap, receivedMediaKeyEvent:event)
        keyCode = (event.data1 & 0xFFFF0000) >> 16
        keyFlags = event.data1 & 0x0000FFFF
        keyIsPressed = (keyFlags & 0xFF00) >> 8 == 0xA
        keyRepeat = (keyFlags & 0x1)
        
        if keyIsPressed
            if keyCode == 20
                NSNotificationCenter.defaultCenter.postNotificationName('ThumperPreviousTrack', object:nil)
            elsif keyCode == 19
                NSNotificationCenter.defaultCenter.postNotificationName('ThumperNextTrack', object:nil)
            elsif keyCode == 16
                NSNotificationCenter.defaultCenter.postNotificationName('ThumperPlayToggle', object:nil)
            end
        end
    end
    
    def applicationWillTerminate(a_notification)
        @playing_song_object.stop if @playing_song_object.rate != 0
    end
    
    def applicationDidFinishLaunching(a_notification)
        #media keys
        keyTap = SPMediaKeyTap.alloc.initWithDelegate(self)
        if SPMediaKeyTap.usesGlobalMediaKeyTap
            keyTap.startWatchingMediaKeys
        end
                
        server_url_field.stringValue = @server_url if @server_url
        username_field.stringValue = @username if @username
        password_field.stringValue = @password if @password
        @bitrate && @bitrate == 0 ? bitrate_field.stringValue = "Unlimited" : bitrate_field.stringValue = @bitrate
        
        @app_version.stringValue = "Version: #{NSBundle.mainBundle.infoDictionary.objectForKey(:CFBundleShortVersionString)}"
        
        if @current_playlist.length > 0
            @playing_song = 0
            song = @current_playlist[0]
            if File.exists?(song[:cache_path])
                @playing_queue.sync do 
                    @playing_song_object = QTMovie.alloc.initWithFile(song[:cache_path], error:nil)
                end
            else
                url_string = "#{@server_url}/rest/stream.view?u=#{@username}&p=#{@enc_password}&v=1.7.0&c=Thumper&f=xml&id=#{song[:id]}&format=mp3&estimateContentLength=true"
                url_string << "&maxBitRate=#{@bitrate}" if @bitrate && @bitrate != 0 && @bitrate != ""
                url = NSURL.alloc.initWithString(url_string)
                @playing_song_object.stop if @playing_song_object
                @playing_queue.sync do 
                    @playing_song_object = QTMovie.alloc.initWithURL(url, error:nil)
                    @playing_song_object_progress.startAnimation(nil)
                end
            end
            start_timer unless @playing_song_object.nil?
            NSNotificationCenter.defaultCenter.addObserver(self, selector:'loadStateChanged:', name:QTMovieLoadStateDidChangeNotification, object:@playing_song_object)
            NSNotificationCenter.defaultCenter.addObserver(self, selector:'songEnded:', name:QTMovieDidEndNotification, object:@playing_song_object)
            set_playing_info
            set_playing_cover_art
            reload_current_playlist
        else
            
            @playing_song_object = QTMovie.alloc
        end

        @username.nil? || @password.nil? || @server_url.nil? ? show_server_info_modal : setup_subsonic_conneciton
       
        NSNotificationCenter.defaultCenter.addObserver(self, selector:'rateDidChange:', name:QTMovieRateDidChangeNotification, object:nil)
        check_for_update
        
        status_bar = NSStatusBar.systemStatusBar
        @status_item = status_bar.statusItemWithLength(NSVariableStatusItemLength)
        @status_item.setImage(NSImage.imageNamed('MenuIcon'))
        @status_item.setHighlightMode(true)
        @thumperMenu = ThumperMenu.new
    end
    
    def check_for_update
        @playing_queue.async do
            current_version = NSBundle.mainBundle.infoDictionary.objectForKey(:CFBundleShortVersionString).split(".")
            url = NSURL.URLWithString("http://www.thumperapp.com/current_version")
            request = NSMutableURLRequest.requestWithURL(url, cachePolicy:NSURLRequestReloadIgnoringCacheData, timeoutInterval:5.0)
            response = String.new(NSURLConnection.sendSynchronousRequest(request, returningResponse:nil, error:nil))
            latest_version = response.split(".")
            up_to_date = true
            3.times do |i|
                if current_version[i].to_i < latest_version[i].to_i
                    up_to_date = false
                    break
                elsif current_version[i].to_i > latest_version[i].to_i
                    break
                end
            end
            if !up_to_date
                @t_update_text.stringValue = "There is a newer version of Thumper available.\n\nCurrent Version: #{current_version.join('.')}\nAvailable Version: #{response}"
                update_modal = SimpleModal.new(@main_window, @t_update_window)
                update_modal.add_outlet(@t_update_button) do
                    url = NSURL.URLWithString "macappstore://itunes.apple.com/us/app/thumper/id436422990?mt=12ls=1ign-msr=http%3A%2F%2Fwww.thumperapp.com%2F"
                    NSWorkspace.sharedWorkspace.openURL(url)
                end
                update_modal.add_outlet(@t_update_cancel_button) do
                    nil
                end
                update_modal.show
            end
        end
        
    end
    
    def applicationShouldHandleReopen(app, hasVisibleWindows: windows)
        @main_window.makeKeyAndOrderFront(nil)        
        return true
    end
    
    
    def show_server_info_modal
        @status_label.stringValue = "Offline"
        NSApp.beginSheet(server_info_window,
                         modalForWindow:main_window,
                         modalDelegate:self,
                         didEndSelector:nil,
                         contextInfo:nil) 
    end
    
    def preferences(sender)
        show_server_info_modal
    end
        
    def submit_connection_info(sender)
        server_url_field.stringValue.scan("http").length > 0 ? url = server_url_field.stringValue : url = "http://" + server_url_field.stringValue
        @db_queue.sync do
            DB[:songs].delete
            DB[:artists].delete
            DB[:albums].delete
            DB[:playlist_songs].delete
            DB[:smart_playlists].delete
            @current_playlist = []
            @playing_song_object = QTMovie.alloc
            @playing_song = nil
            @artists = []
            @albums = []
            @songs = []
            @playlists = []
            @playlist_songs = []
            @search_results = []
            @now_playing = []
            reload_current_playlist
            reload_albums
            reload_artists
            reload_playlists
            reload_songs
            @playing_title.stringValue = ""
            @playing_info.stringValue =  ""
            @playing_song_object_progress.setHidden(true)
            set_playing_cover_art
        end
        @server_url = url
        @current_server_url = url
        @username = username_field.stringValue
        @password = password_field.stringValue
        @bitrate =  bitrate_field.stringValue
        NSUserDefaults.standardUserDefaults['thumper.com.server_url'] = @server_url
        NSUserDefaults.standardUserDefaults['thumper.com.username'] = @username
        NSUserDefaults.standardUserDefaults['thumper.com.bitrate'] = @bitrate
        NSUserDefaults.standardUserDefaults['thumper.com.password'] = @password
        p = []
        String.new(@password).each_byte{|c| p << sprintf("%02X", c)}
        @enc_password = 'enc:' + p.join('')
        NSUserDefaults.standardUserDefaults.synchronize
        NSApp.endSheet(server_info_window)
        server_info_window.orderOut(sender)
        if @server_url.empty? || @username.empty? || @password.empty?
            show_server_info_modal
        else
            get_server_ip if @server_url.scan('subsonic.org').length > 0
            setup_subsonic_conneciton
        end
    end
    
    def setup_subsonic_conneciton
        get_server_ip if @server_url && @current_server_url.scan('subsonic.org').length > 0
        #NSLog "Connecting to subsonic"
        @subsonic = Subsonic.new(self, @current_server_url, username, password)
        @subsonic.ping(@subsonic, :ping_response)
    end
    
    def hide_connection_info(sender)
        NSApp.endSheet(server_info_window)
        server_info_window.orderOut(sender)
    end
    
    def get_artist_indexes
        @artists_progress.startAnimation(nil)
        @artists = []
        DB[:artists].all.each do |artist|
            @artists << {:name => artist[:name], :id => artist[:id]}
        end
        @all_artists = @artists
        reload_artists
        @subsonic.artists(@subsonic, :artists_response)
    end
    
    def get_playlists
        @playlists_progress.startAnimation(nil)
        @subsonic.playlists(@subsonic, :playlists_response)
    end
    
    def get_playlist(id)
        @playlist_songs_progress.startAnimation(nil)
        @subsonic.playlist(id, @subsonic, :playlist_response)
    end
    
    def reload_artists
        @artists.count != 1 ? word = " Artists" : word = " Artist"
        @artist_count_label.stringValue = @artists.count.to_s + word
        @artist_indexes_table_view.reloadData
        @artist_indexes_table_view.deselectAll(nil)
        @artist_indexes_table_view.scrollRowToVisible(0)
        reload_albums
    end
    
    def reload_albums
        @albums.count != 1 ? word = " Albums" : word = " Album"
        @album_count_label.stringValue = @albums.count.to_s + word
        @albums_table_view.reloadData
        @albums_table_view.enabled = true
        @albums_table_view.deselectAll(nil)
        @albums_table_view.scrollRowToVisible(0)
        reload_songs
    end
    
    def update_albums(sender)
        get_artist_albums(artists[artist_indexes_table_view.selectedRow][:id])
    end
    
    def update_qp_albums(sender)
        @qp_offset = 0
        @albums_table_view.scrollRowToVisible(0)
        get_quick_playlist({:type => quick_playlists[quick_playlists_table_view.selectedRow][1]}) 
    end
    
    def reload_songs
        @songs.count != 1 ? word = " Songs" : word = " Song"
        @songs_count_label.stringValue = @songs.count.to_s + word
        @songs_table_view.reloadData
        @songs_table_view.deselectAll(nil)
        @songs_table_view.enabled = true
        @songs_table_view.scrollRowToVisible(0)
    end
    
    def reload_playlists
        @playlists.length != 1? word = " Playlists" : word = " Playlist" 
        @playlists_count_label.stringValue = @playlists.length.to_s + word
        @playlists_table_view.deselectAll(nil)
        @playlists_table_view.reloadData
        @playlists_table_view.scrollRowToVisible(0)
    end
    
    def reload_playlist_songs
        @playlist_songs.length != 1? word = " Songs" : word = " Song" 
        @playlist_songs_count_label.stringValue = @playlist_songs.length.to_s + word
        @playlist_songs_table_view.deselectAll(nil)
        @playlist_songs_table_view.reloadData
        @playlist_songs_table_view.enabled = true
        @playlist_songs_table_view.scrollRowToVisible(0)
    end
    
    def reload_current_playlist
        current_playlist.count != 1 ? word = " Songs" : word = " Song"
        current_playlist_count_label.stringValue = current_playlist.count.to_s + word
        current_playlist_table_view.reloadData
        @playing_song ? scroll_to = @playing_song : scroll_to = 0
        current_playlist_table_view.scrollRowToVisible(scroll_to)
    end
    
    def add_to_current_playlist(song, reload = true)
        return if song.nil?
        current_playlist << song
        reload_current_playlist if reload
        if current_playlist.length == 1
            @playing_song = 0
            play_song
        elsif @playing_song_object.rate == 0.0 && @playing_song_object.attributeForKey(QTMovieLoadStateAttribute) >= 2000
            @playing_song = current_playlist.length - 1
            play_song
        elsif @playing_song == current_playlist.length - 2
            next_song = @current_playlist[@playing_song + 1]
            unless File.exists?(next_song[:cache_path])
                @subsonic.download_media(next_song[:cache_path], next_song[:id], @subsonic, :download_media_response) if @downloading_enabled
                get_cover_art(next_song[:cover_art].split("/").last.split(".").first)
            end
        end
        @db_queue.async do
            DB[:playlist_songs].insert(:name => "Current", :playlist_id => "666current666", :song_id => song[:id])
        end
    end
    
    def get_artist_albums(id)
        return if id.empty?
        @albums_progress.startAnimation(nil)
        @albums_progress.setHidden(false)
        @albums = []
        DB[:albums].filter(:artist_id => id).all.each do |album|
            @albums << {:id => album[:id], :title => album[:title], :cover_art => album[:cover_art], :artist_id => album[:artist_id]} 
        end
        reload_albums
        @subsonic.albums(id, @subsonic, :albums_response)
    end
    
    def get_quick_playlist(options)
        return unless options[:type]
        @albums_progress.startAnimation(nil)
        @albums_progress.setHidden(false)
        @subsonic.quick_playlists(options, @subsonic, :qp_response)
    end
    
    def share_item(sender)
        #Request the share 
        @subsonic.share(sender.representedObject, @subsonic, :share_response)
    end
    
    def rate_item(sender)
        @subsonic.rate(sender.representedObject)
    end
    
    def get_smart_playlist(options)
        @playlist_songs_progress.startAnimation(nil)
        @subsonic.smart_playlist(options, @subsonic, :smart_playlist_response)
    end
        
    def applicationDockMenu(sender)
        dock_menu = NSMenu.alloc.initWithTitle("Thumper")
        if @playing_song_object && @playing_song
            now_playing_item = NSMenuItem.alloc.init
            now_playing_item.setTitle("Now Playing:")
            now_playing_item.setEnabled(true)
            dock_menu.addItem(now_playing_item)
            
            title_item = NSMenuItem.alloc.init
            title_item.setTitle(@current_playlist[@playing_song][:title] + " - #{@current_playlist[@playing_song][:duration]}")
            title_item.setIndentationLevel(1)
            title_item.setEnabled(true)
            dock_menu.addItem(title_item)

            artist_item = NSMenuItem.alloc.init
            artist_item.setTitle(@current_playlist[@playing_song][:artist])
            artist_item.setIndentationLevel(1)
            artist_item.setEnabled(true)
            dock_menu.addItem(artist_item)
            
            dock_menu.addItem(NSMenuItem.separatorItem)
        end
        
        if @current_playlist.length > 0
            play_toggle = NSMenuItem.alloc.init
            play_toggle.setTarget(self)
            play_toggle.setAction("play_toggle_button:")
            if @playing_song_object.rate != 0
                play_toggle.setTitle("Pause")
            else
                play_toggle.setTitle("Play")
            end
            dock_menu.addItem(play_toggle)
            
            stop_item = NSMenuItem.alloc.init
            stop_item.setTarget(self)
            stop_item.setAction("stop_button:")
            stop_item.setTitle("Stop")
            dock_menu.addItem(stop_item)

            play_next = NSMenuItem.alloc.init
            play_next.setTarget(self)
            play_next.setAction("play_next_button:")
            play_next.setTitle("Next")
            dock_menu.addItem(play_next)
            
            play_previous = NSMenuItem.alloc.init
            play_previous.setTarget(self)
            play_previous.setAction("play_previous_button:")
            play_previous.setTitle("Previous")
            dock_menu.addItem(play_previous)
        end


        return dock_menu
    end
    
    def get_album_songs(id)
        return if id.empty?
        @songs_progress.startAnimation(nil)
        @songs = []
        DB[:songs].filter(:album_id => id).all.each do |song|
            @songs << {:id => song[:id], :title => song[:title], :duration => song[:duration], :track => song[:track], 
                :artist => song[:artist], :album => song[:album], :bitrate => song[:bitrate], :year => song[:year], :genre => song[:genre],
                :size => song[:size], :suffix => song[:suffix], :album_id => song[:ablum_id], :cover_art => song[:cover_art], 
                :path => song[:path]} 
        end
        reload_songs
        @subsonic.songs(id, @subsonic, :songs_response)
    end
    
    def get_cover_art(cover_art_id)
        return if cover_art_id.nil? || cover_art_id.empty?
        @subsonic.cover_art(cover_art_id, @subsonic, :image_response)
    end
    
    def format_time (timeElapsed)
                
        #find the seconds
        seconds = timeElapsed % 60
        
        #find the minutes
        minutes = (timeElapsed / 60) % 60
        
        #find the hours
        hours = (timeElapsed/3600)
        
        result = ""
        result << hours.to_s + ":" if hours > 0
        minutes > 9 || hours > 0 ? result << format("%02d", minutes.to_s) : result << minutes.to_s
        
        #format the time
        
        return result << ":" + format("%02d",seconds.to_s)
    end
    
    def play_song
        @playing_song = 0 if @playing_song.nil? 
        song = @current_playlist[@playing_song]
        #NSLog "#{song}"
        #growl_song
        if File.exists?(song[:cache_path])
            #NSLog "Playing song from cache"
            @playing_song_object_progress.stopAnimation(nil)
            @playing_queue.sync do 
                @playing_song_object.stop if @playing_song_object
                @playing_song_object = QTMovie.alloc.initWithFile(song[:cache_path], error:nil)
                if @current_playlist.length >= @playing_song + 2
                    download_next
                end
            end
        else
            url_string = "#{@server_url}/rest/stream.view?u=#{@username}&p=#{@enc_password}&v=1.4.0&c=Thumper&v=1.4.0&f=xml&id=#{song[:id]}&format=mp3&estimateContentLength=true"
            url_string << "&maxBitRate=#{@bitrate}" if @bitrate && @bitrate != 0 && @bitrate != ""
            url = NSURL.alloc.initWithString(url_string)
            #NSLog "Streaming song"
            @playing_queue.sync do 
                @playing_song_object.stop if @playing_song_object
                @downloading_song.cancel if @downloading_song
                @playing_song_object = QTMovie.alloc.initWithURL(url, error:nil)
                @playing_song_object_progress.startAnimation(nil)
                @playing_song_object_progress.setUsesThreadedAnimation(true)
                @playing_song_object_progress.setHidden(false)
            end
        end
        NSNotificationCenter.defaultCenter.addObserver(self, selector:'loadStateChanged:', name:QTMovieLoadStateDidChangeNotification, object:@playing_song_object)
        NSNotificationCenter.defaultCenter.addObserver(self, selector:'songEnded:', name:QTMovieDidEndNotification, object:@playing_song_object)
        @playing_song_object.setVolume(@settings.values.valueForKey('volume').to_f)
        start_timer if @progress_timer.nil?
        @playing_song_object.autoplay
        set_playing_info
        set_playing_cover_art
        @play_button.setImage(NSImage.imageNamed("Pause"))
        current_playlist_table_view.scrollRowToVisible(@playing_song)
        current_playlist_table_view.reloadData
        get_cover_art(song[:cover_art].split("/").last.split(".").first)
        @subsonic.scrobble(song[:id], @subsonic, :scrobble_response)
    end
    
    def display_movie
        @playing_song_object.attachToCurrentThread
        @movie_panel.close if @movie_panel
        size = @playing_song_object.attributeForKey(QTMovieNaturalSizeAttribute).sizeValue
        rect = NSRect.new([50, 50], [size.width, size.height])
        
        unless @movie_panel
            @movie_panel = NSPanel.alloc.initWithContentRect(rect,
                                                            styleMask:NSTitledWindowMask | NSClosableWindowMask | NSUtilityWindowMask |  NSResizableWindowMask | NSHUDWindowMask,
                                                            backing:NSBackingStoreBuffered,
                                                            defer:false,
                                                            screen: nil)
            @movie_panel.setHidesOnDeactivate(false)
            @movie_panel.setReleasedWhenClosed(false)
            @movie_panel.orderFrontRegardless
            @movie_panel.center
            #@movie_panel.setMovable(true)
            @movie_panel.contentView.setAutoresizesSubviews(true)
        end
        
        @movie_panel.setAspectRatio(size)
        @movie_panel.setTitle(@current_playlist[@playing_song][:title])
        @movie_panel.setContentSize(size)
        p @current_playlist[@playing_song][:id]
        
        movie_view = ThumperMovie.alloc.initWithFrame(NSRect.new([0,0], [size.width, size.height]))
        movie_view.setAutoresizingMask(NSViewWidthSizable | NSViewHeightSizable)
        movie_view.setMovie(@playing_song_object)
        movie_view.setControllerVisible(false)
        
        @movie_panel.setContentView(movie_view)
        @movie_panel.makeKeyAndOrderFront(nil)
        @movie_panel.display
    end
    
    def change_notification_text(new_text)
        #@notification_view.setString(new_text)
        #@notification_timer.invalidate if @notification_timer
        #NSAnimationContext.beginGrouping
        #NSAnimationContext.currentContext.setDuration(0.5)
        #show_notification_view
        #NSAnimationContext.endGrouping
    end
    
    def show_notification_view
        #if @notification_view.string
        #    @notification_view.setString(@notification_view.string)
        #    @notification_view.animator.setFrameSize([100,22])
        #    @notification_timer = NSTimer.scheduledTimerWithTimeInterval 10.0,
        #        target: self,
        #        selector: 'hide_notification_view:',
        #        userInfo: nil,
        #        repeats: false
        #end
    end
    
    def hide_notification_view(timer)
        #@notification_timer = nil
        #NSAnimationContext.beginGrouping
        #NSAnimationContext.currentContext.setDuration(0.5)
        #@notification_view.animator.setFrameSize([0,22])
        #NSAnimationContext.endGrouping
        #if @playing_song
        #    song = @current_playlist[@playing_song]
        #    @notification_view.setString("#{song[:title]} by #{song[:artist]}")
        #end
    end
    
    def set_playing_info
        if @playing_song
            song = @current_playlist[@playing_song]
            title = song[:title]
            info = "#{song[:artist]} - #{song[:album]}" 
        else
            title = ""
            info = ""
        end
        @playing_title.stringValue = title
        @playing_info.stringValue =  info

    end
    
    def set_playing_cover_art
        if @playing_song
            image = @current_playlist[@playing_song][:cover_art]
            if File.exists?(image)
                @playing_cover_art.setImage(NSImage.alloc.initWithContentsOfFile(image))
            else
                @playing_cover_art.setImage(NSImage.imageNamed("album"))
            end 
        else
            @playing_cover_art.setImage(NSImage.imageNamed("album"))
        end
    end
    
    def growl_song
        song_attributes = current_playlist[playing_song]
        if File.exists?(song_attributes[:cover_art])
            image = NSImage.alloc.initWithContentsOfFile(song_attributes[:cover_art])
            else
            image = NSImage.imageNamed("album")
        end
        @notification_queue.add_notification({:title => "Thumper", :image => image, :message => "Song: #{song_attributes[:title]}\nArtist: #{song_attributes[:artist]}\nAlbum: #{song_attributes[:album]}\nLength: #{song_attributes[:duration]}"})
        #g = Growl.new("Thumper", ["notification"], image)
        #g.notify("notification", "#{song_attributes[:title]}", "Artist: #{song_attributes[:artist]}\nAlbum: #{song_attributes[:album]}\nLength: #{song_attributes[:duration]}") 
    end
    
    def play_toggle_button(sender)
        play_toggle 
    end
    
    def start_timer
        @progress_timer = NSTimer.scheduledTimerWithTimeInterval 0.2,
                            target: self,
                            selector: 'update_progress_bar:',
                            userInfo: nil,
                            repeats: true
    end
    
    def cancel_timer
        @progress_timer.invalidate if @progress_timer
        @progress_timer = nil
        #NSLog "canceled Timer"
    end
    
    def play_toggle 
        if @current_playlist.length > 0
            if @playing_song_object.rate != 0
                @playing_song_object.stop
                @play_button.setImage(NSImage.imageNamed("Play"))
                cancel_timer
            else
                @playing_song_object.play 
                @play_button.setImage(NSImage.imageNamed("Pause"))
                start_timer
            end
        end
    end
    
    def play_previous_button(sender)
        play_previous
    end
    
    def play_previous
        if @playing_song_object.rate != 0 && (@playing_song_object.currentTime.timeValue/@playing_song_object.currentTime.timeScale.to_f).to_i > 3
            @playing_song_object.setCurrentTime(QTTime.new(0,1,false))
        elsif @playing_song != 0 && !@playing_song.nil? && @current_playlist.length > 1
            @playing_song -= 1
            play_song
        elsif @current_playlist.length > 1 && !@playing_song.nil?
            @playing_song = current_playlist.length - 1
            play_song
        end
    end
    
    def play_next_button(sender)
        play_next 
    end
    
    def stop_button(sender)
        if @playing_song_object
            @play_button.setImage(NSImage.imageNamed("Play"))
            @playing_song_object.stop 
            @playing_song_object.setCurrentTime(QTTime.new(0,1,false))
            cancel_timer
        end
    end
    
    def volume_changed(sender)
        @volume = @settings.values.valueForKey('volume').to_f
        @playing_song_object.setVolume(@settings.values.valueForKey('volume').to_f)
    end
    
    def play_next 
        if @repeat_single == true
            @playing_song_object.setCurrentTime(QTTime.new(0,1,false))
            play_song
            #NSLog "Repeat Single"
        elsif @repeat_all == true && @playing_song == @current_playlist.length - 1
            @playing_song = 0
            play_song
            #NSLog "Repeat all"
        elsif @shuffle == true
            unless @current_playlist.length == 1
                current = @playing_song
                begin
                    @playing_song = rand(current_playlist.length)
                end while @playing_song == current
            end
            play_song
            #NSLog "Shuffle"
        elsif !@playing_song.nil? && !@current_playlist[@playing_song + 1].nil?
            @playing_song += 1
            play_song
        end
    end
    
    def repeat_single(sender)
        if @repeat_single == true
            @repeat_single = false 
            sender.setState(NSOffState) 
            @repeat_button.setState(NSOffState)
            @repeat_button.setTitle("Repeat")
        else 
            @repeat_single = true
            @repeat_all = false
            sender.setState(NSOnState)
            @repeat_all_menu_item.setState(NSOffState)
            @repeat_button.setState(NSOnState)
            @repeat_button.setTitle("Repeat")
        end
    end
    
    def repeat_button_action(sender)
        if @repeat_single == true
            #toggle to repeat all
            #NSLog "Repeat all on"
            @repeat_single = false
            @repeat_all = true
            @repeat_one_menu_item.setState(NSOffState)
            @repeat_button.setTitle("Repeat All")
            @repeat_all_menu_item.setState(NSOnState)
            sender.setState(NSOnState)
        elsif @repeat_all == true
            #turn all repeat off
            #NSLog "Repeat off"
            @repeat_single = false
            @repeat_all = false
            @repeat_one_menu_item.setState(NSOffState)
            @repeat_all_menu_item.setState(NSOffState)
            @repeat_button.setTitle("Repeat")
            sender.setState(NSOffState)
        else
            #turn on repeat single
            #NSLog "Repeat on"
            @repeat_single = true
            @repeat_all = false
            @repeat_one_menu_item.setState(NSOnState)
            @repeat_button.setTitle("Repeat")
            @repeat_all_menu_item.setState(NSOffState)
            sender.setState(NSOnState)
        end
    end
    
    def repeat_all(sender)
        if @repeat_all == true 
            @repeat_all = false
            @repeat_all_menu_item.setState(NSOffState)
            @repeat_button.setState(NSOffState)
            @repeat_button.setTitle("Repeat")
        else
            @repeat_all = true 
            @repeat_single = false
            sender.setState(NSOnState)
            @repeat_one_menu_item.setState(NSOffState)
            @repeat_all_menu_item.setState(NSOnState)
            @repeat_button.setState(NSOnState)
            @repeat_button.setTitle("Repeat All")
        end
    end
    
    def repeat_off(sender)
        @repeat_one_menu_item.setState(NSOffState)
        @repeat_all_menu_item.setState(NSOffState)
        @repeat_button.setState(NSOffState)
        @repeat_button.setTitle("Repeat")
        @repeat_all = false
        @repeat_single = false
    end
    
    def playNext(notificaiton)
        play_next
    end
    
    def playToggle(notificaiton)
        play_toggle
    end
    
    def playPrevious(notificaiton)
        play_previous
    end
    
    def volumeUp(notification)
        increaseVolume(nil)
    end
    
    def volumeDown(notificaiton)
        decreaseVolume(nil)
    end
    
    def windowFront(notification)
        NSRunningApplication.runningApplicationsWithBundleIdentifier("com.thumperapp.Thumper").lastObject.activateWithOptions(NSApplicationActivateAllWindows)
        NSApp.activateIgnoringOtherApps(true)
        @main_window.makeKeyAndOrderFront(@main_window)
    end
    
    def decreaseVolume(sender)
        @volume < 0.1 ? @volume = 0.0 : @volume -= 0.1
        @playing_song_object.setVolume(@volume)
        @volume_slider.setFloatValue(@volume)
        @settings.values.setValue(@volume, forKey: 'volume')
        NSUserDefaults.standardUserDefaults.synchronize
    end
    
    def increaseVolume(sender)
        @volume > 0.9 ? @volume = 1.0 : @volume += 0.1
        @playing_song_object.setVolume(@volume)
        @volume_slider.setFloatValue(@volume)
        @mute_menu_item.setState(NSOffState)
        @settings.values.setValue(@volume, forKey: 'volume')
        NSUserDefaults.standardUserDefaults.synchronize
    end
    
    def muteVolume(sender)
        if @volume > 0.0
            @mute_volume = @volume
            @volume = 0.0
            sender.setState(NSOnState)
        else
            @volume = @mute_volume
            sender.setState(NSOffState)
        end
        @playing_song_object.setVolume(@volume)
        @volume_slider.setFloatValue(@volume)
    end
    
    def shuffle_all(sender)
        if @shuffle == true
            @shuffle = false
            @shuffle_button.setState(NSOffState)
            @shuffle_menu_item.setState(NSOffState)
        else
            @shuffle = true
            @shuffle_button.setState(NSOnState)
            @shuffle_menu_item.setState(NSOnState)
        end
    end
    
    def songEnded(notification)
		
    end
    
    def rateDidChange(notification)
        if @playing_song_object && @playing_song_object.rate != 0
            song = @current_playlist[@playing_song]            
            if song[:isVideo] == "true"
                change_notification_text("You're watching #{song[:title]}")
                display_movie
            else
                @movie_panel.close if @movie_panel
                change_notification_text("#{song[:title]} by #{song[:artist]}")
            end
        end
        @thumperMenu.build_menu
    end
    
    def loadStateChanged(notification)
        if @playing_song_object.attributeForKey(QTMovieLoadStateAttribute) == 100000
            @playing_song_object_progress.stopAnimation(nil)
            @playing_song_object_progress.setHidden(true)
            path = @current_playlist[@playing_song][:cache_path]

            path_step = "/"
            split_path = path.split('/')
            split_path.delete_at(0)
            split_path.delete_at(split_path.length - 1)
            split_path.each do |dir|
                path_step << dir
                if !File.exists?(path_step)
                    Dir.mkdir(path_step)
                end
                path_step << '/'
            end
            #data = @playing_song_object.movieFormatRepresentation
            error = Pointer.new_with_type("@")
            result = @playing_song_object.writeToFile(path, withAttributes:{QTMovieFlatten => true, QTMovieExport => true}, error:error) unless File.exists?(path)
            if error[0]
                NSLog error[0].localizedDescription
                NSLog error[0].code
            end
            
            if @current_playlist.length >= @playing_song + 2
                download_next
            end
		elsif @playing_song_object.attributeForKey(QTMovieLoadStateAttribute) == 20000
			#ready to play
            set_playing_cover_art
        end
    end
    
    def download_next
        next_song = @current_playlist[@playing_song + 1]
        #NSLog "#{next_song[:suffix]}"
        if !File.exists?(next_song[:cache_path])
            change_notification_text("Attempting to download the next song, #{next_song[:title]} by #{next_song[:artist]}")
            #@notification_queue.add_notification({:title => "Downloading next song....", :message => "Attempting to download the next song in the current playlist.", :image => NSImage.imageNamed("LogoWhite")}) if @downloading_enabled
            #g = Growl.new("Thumper", ["notification"])
            #g.notify("notification", "Downloading next song...", "Attempting to download the next song in the current playlist.", {:NotificationPriority => -1})
            
            path = next_song[:cache_path]
            @subsonic.download_media(path, next_song[:id], @subsonic, :download_media_response)
        end
        if !File.exists?(next_song[:cover_art])
            get_cover_art(next_song[:cover_art].split("/").last.split(".").first)
        end
    end
    
    def update_progress_bar(timer)
        Dispatch::Queue.new('com.Thumper.play_progress').sync do 
            if @playing_song_object.currentTime
                time = @playing_song_object.currentTime.timeValue/@playing_song_object.currentTime.timeScale.to_f
                duration = @playing_song_object.duration.timeValue/@playing_song_object.duration.timeScale.to_f
                @playing_time_elapsed.stringValue = format_time(time.to_i)
                @playing_time_remaining.stringValue = "-#{format_time((duration - time).to_i)}"
                @playing_song_progress_view.progressPercent = time/duration * 100.00
                @playing_song_progress_view.display 
                if time == duration && @playing_song_object.attributeForKey(QTMovieLoadStateAttribute) && @playing_song_object.attributeForKey(QTMovieLoadStateAttribute) >= 20000
                    @playing_song_object.setCurrentTime(QTTime.new(0, 1, false))
                    @playing_song_object.stop
                    update_progress_bar(@progress_timer)
                    @play_button.setImage(NSImage.imageNamed("Play"))
                    play_next if @current_playlist.length > @playing_song + 1 || @shuffle == true || @repeat_single == true || @repeat_all == true
                end
            else
                @playing_time_elapsed.stringValue = ""
                @playing_time_remaining.stringValue = ""
            end
        end
    end
end

