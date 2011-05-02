#
#  ThumperDelegate.rb
#  Thumper
#
#  Created by Daniel Westendorf on 4/2/11.
#  Copyright 2011 Daniel Westendorf. All rights reserved.
#
class ThumperDelegate
    attr_accessor :main_window, :status_label, :subsonic, :format_time
    attr_accessor :server_info_window, :server_url_field, :username_field, :password_field
    attr_accessor :server_url, :username, :password
    attr_accessor :artists, :all_artists, :artist_indexes_table_view, :artist_count_label, :artists_progress
    attr_accessor :albums, :albums_table_view, :album_count_label, :albums_progress
    attr_accessor :songs, :songs_table_view, :songs_count_label, :songs_progress
    attr_accessor :current_playlist, :current_playlist_table_view, :current_playlist_count_label
    attr_accessor :playing_song_object, :playing_song, :playing_song_object_progress
    attr_accessor :artist_reload_button, :album_reload_button, :song_reload_button
    attr_accessor :playlists, :playlists_table_view, :playlist_songs, :playlist_songs_table_view, :playlists_count_label, :playlist_songs_count_label
    attr_accessor :playlists_progress, :playlist_songs_progress
	attr_accessor :playing_song_progress_view, :play_toggle_button, :play_previous_button, :play_next_button, :playing_cover_art, :playing_time_elapsed, :playing_time_remaining, :play_button, :volume_slider, :playing_title, :playing_info, :stop_button
    attr_accessor :playing_queue, :db_queue
    attr_accessor :mute_menu_item, :repeat_all_menu_item, :repeat_one_menu_item
    attr_accessor :demo_window, :demo_text
    attr_accessor :about_window
    
    def initialize
        @artists = []
        @albums = []
        @songs = []
        @playlists = DB[:playlist_songs].group(:name).all.collect {|p| {:id => p[:playlist_id], :name => p[:name]} }
        @playing_queue = Dispatch::Queue.new('com.Thumper.playback')
        @db_queue = Dispatch::Queue.new('com.Thumper.db')
        @volume = 1.0
        @playlist_songs = []
        @shuffle = false
        @repeat_single = false
        @repeat_all = false
        @current_playlist = DB[:playlist_songs].join(:songs, :id => :song_id).filter(:playlist_id => '666current666').all
        @current_playlist.each {|s| s[:id] = s[:song_id]; s.delete(:song_id)}
        @progress_timer = NSTimer.scheduledTimerWithTimeInterval 0.2,
                                                        target: self,
                                                        selector: 'update_progress_bar:',
                                                        userInfo: nil,
                                                        repeats: true

        @server_url = NSUserDefaults.standardUserDefaults['thumper.com.server_url'] unless NSUserDefaults.standardUserDefaults['thumper.com.server_url'].nil?
        @username = NSUserDefaults.standardUserDefaults['thumper.com.username'] unless NSUserDefaults.standardUserDefaults['thumper.com.username'].nil?
        @password = NSUserDefaults.standardUserDefaults['thumper.com.password'] unless NSUserDefaults.standardUserDefaults['thumper.com.password'].nil?
        
        p = []
        String.new(@password).each_byte{|c| p << sprintf("%02X", c)} if @password
        @enc_password = 'enc:' + p.join('') if @password
        
        get_server_ip if @server_url.scan('subsonic.org').length > 0 if @server_url
        
        NSNotificationCenter.defaultCenter.addObserver(self, selector:'playNext:', name:"ThumperNextTrack", object:nil)
        NSNotificationCenter.defaultCenter.addObserver(self, selector:'playPrevious:', name:"ThumperPreviousTrack", object:nil)
        NSNotificationCenter.defaultCenter.addObserver(self, selector:'playToggle:', name:"ThumperPlayToggle", object:nil)
    end
    
    def get_server_ip
        Dispatch::Queue.new('com.Thumper.network').async do
            subdomain = @server_url.split('.').first.split('/').last
            NSLog "Subdomain #{subdomain}"
            url = NSURL.URLWithString("http://subsonic.org/backend/redirect/get.view?redirectFrom=#{subdomain}")
            request = NSMutableURLRequest.requestWithURL(url, cachePolicy:NSURLRequestReloadIgnoringCacheData, timeoutInterval:60.0)
            response = String.new(NSURLConnection.sendSynchronousRequest(request, returningResponse:nil, error:nil)).split(' ').first
            response[response.length - 1] = ""
            NSLog "Response: #{response}"
            @server_url = response
        end
    end
    
    def demo_close(sender)
        exit
    end
    
    def show_about(sender)
        @about_window.makeKeyAndOrderFront(nil)
        return true
    end
    
    def applicationDidFinishLaunching(a_notification)
        expire = DateTime.parse('2011-05-14')
        if DateTime.now > expire
            NSLog "Demo period has expired"
            @demo_text.stringValue = "Thank you for using Thumper, hopefully it was an enjoyable experience. The demo period for Thumper has expired. If you like the app and would like to continue using it, please visit http://www.thumperapp.com"
            NSApp.beginSheet(demo_window, modalForWindow:main_window, modalDelegate:self, didEndSelector:nil, contextInfo:nil)
        end
        if @current_playlist.length > 0
            @playing_song = 0
            song = @current_playlist[0]
            if File.exists?(song[:cache_path])
                Dispatch::Queue.new('com.Thumper.playback').sync do 
                    @playing_song_object = QTMovie.alloc.initWithFile(song[:cache_path], error:nil)
                end
            else
                url = NSURL.alloc.initWithString("#{@server_url}/rest/stream.view?u=#{@username}&p=#{@enc_password}&v=1.4.0&c=Thumper&v=1.4.0&f=xml&id=#{song[:id]}")
                @playing_song_object.stop if @playing_song_object
                @playing_queue.sync do 
                    @playing_song_object = QTMovie.alloc.initWithURL(url, error:nil)
                    @playing_song_object_progress.startAnimation(nil)
                end
            end
            NSNotificationCenter.defaultCenter.addObserver(self, selector:'loadStateChanged:', name:QTMovieLoadStateDidChangeNotification, object:@playing_song_object)
            NSNotificationCenter.defaultCenter.addObserver(self, selector:'songEnded:', name:QTMovieDidEndNotification, object:@playing_song_object)
            set_playing_info
            set_playing_cover_art
            reload_current_playlist
        else
            @playing_song_object = QTMovie.alloc
        end
        
        @username.nil? || @password.nil? || @server_url.nil? ? show_server_info_modal : setup_subsonic_conneciton
    end
    
    def windowShouldClose(notification)
        @main_window.orderOut(sender)
        return false
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
        server_url_field.stringValue.scan("http").length > 0 ? @server_url = server_url_field.stringValue : @server_url = "http://" + server_url_field.stringValue
        @username = username_field.stringValue
        @password = password_field.stringValue
        NSUserDefaults.standardUserDefaults['thumper.com.server_url'] = @server_url
        NSUserDefaults.standardUserDefaults['thumper.com.username'] = @username
        NSUserDefaults.standardUserDefaults['thumper.com.password'] = @password
        p = []
        String.new(@password).each_byte{|c| p << sprintf("%02X", c)}
        @enc_password = 'enc:' + p.join('')
        NSUserDefaults.standardUserDefaults.synchronize
        NSApp.endSheet(server_info_window)
        server_info_window.orderOut(sender)
        if server_url.empty? || username.empty? || password.empty?
            show_server_info_modal
        else
            get_server_ip if @server_url.scan('subsonic.org').length > 0
            setup_subsonic_conneciton
        end
    end
    
    def setup_subsonic_conneciton
        NSLog "Connecting to subsonic"
        @subsonic = Subsonic.new(self, server_url, username, password)
        @subsonic.ping(@subsonic, :ping_response)
        @subsonic.scrobble(@current_playlist[0][:id], @subsonic, :scrobble_response) if @current_playlist.length > 0
        get_artist_indexes
        get_playlists
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
        artist_indexes_table_view.reloadData
        reload_albums
    end
    
    def reload_albums
        @albums.count != 1 ? word = " Albums" : word = " Album"
        @album_count_label.stringValue = @albums.count.to_s + word
        @albums_table_view.reloadData
        @albums_table_view.enabled = true
        reload_songs
    end
    
    def reload_songs
        @songs.count != 1 ? word = " Songs" : word = " Song"
        @songs_count_label.stringValue = @songs.count.to_s + word
        @songs_table_view.reloadData
        @songs_table_view.enabled = true
    end
    
    def reload_playlists
        @playlists.length != 1? word = " Playlists" : word = " Playlist" 
        @playlists_count_label.stringValue = @playlists.length.to_s + word
        @playlists_table_view.reloadData
    end
    
    def reload_playlist_songs
        @playlist_songs.length != 1? word = " Songs" : word = " Song" 
        @playlist_songs_count_label.stringValue = @playlist_songs.length.to_s + word
        @playlist_songs_table_view.reloadData
        @playlist_songs_table_view.enabled = true
    end
    
    def reload_current_playlist
        current_playlist.count != 1 ? word = " Songs" : word = " Song"
        current_playlist_count_label.stringValue = current_playlist.count.to_s + word
        current_playlist_table_view.reloadData
    end
    
    def add_to_current_playlist(song)
        return if song.nil?
        current_playlist << song
        reload_current_playlist
        if current_playlist.length == 1
            @playing_song = 0
            play_song
        elsif @playing_song == current_playlist.length - 2
            next_song = @current_playlist[@playing_song + 1]
            unless File.exists?(next_song[:cache_path])
                @subsonic.download_media(next_song[:cache_path], next_song[:id], @subsonic, :download_media_response)
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
        @albums = []
        DB[:albums].filter(:artist_id => id).all.each do |album|
            @albums << {:id => album[:id], :title => album[:title], :cover_art => album[:cover_art], :artist_id => album[:artist_id]} 
        end
        reload_albums
        @subsonic.albums(id, @subsonic, :albums_response)
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
    
    def get_cover_art(id)
        return if id.empty?
        @subsonic.cover_art(id, @subsonic, :image_response)
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
        NSLog "#{song}"
        if File.exists?(song[:cache_path])
            NSLog "Playing song from cache"
            @playing_song_object_progress.stopAnimation(nil)
            @playing_queue.sync do 
                @playing_song_object.stop if @playing_song_object
                @playing_song_object = QTMovie.alloc.initWithFile(song[:cache_path], error:nil)
                if @current_playlist.length >= @playing_song + 2
                    next_song = @current_playlist[@playing_song + 1]
                    unless File.exists?(next_song[:cache_path])
                        @subsonic.download_media(next_song[:cache_path], next_song[:id], @subsonic, :download_media_response)
                        get_cover_art(next_song[:cover_art].split("/").last.split(".").first)
                    end
                end
            end
        else
            url = NSURL.alloc.initWithString("#{@server_url}/rest/stream.view?u=#{@username}&p=#{@enc_password}&v=1.4.0&c=Thumper&v=1.4.0&f=xml&id=#{song[:id]}")
            NSLog "Streaming song"
            @playing_queue.sync do 
                @playing_song_object.stop if @playing_song_object
                @playing_song_object = QTMovie.alloc.initWithURL(url, error:nil)
                @playing_song_object_progress.startAnimation(nil)
            end
        end
        NSNotificationCenter.defaultCenter.addObserver(self, selector:'loadStateChanged:', name:QTMovieLoadStateDidChangeNotification, object:@playing_song_object)
        NSNotificationCenter.defaultCenter.addObserver(self, selector:'songEnded:', name:QTMovieDidEndNotification, object:@playing_song_object)
        @playing_song_object.setVolume(@volume)
        @playing_song_object.autoplay
        set_playing_info
        set_playing_cover_art
        @play_button.setImage(NSImage.imageNamed("Pause"))
        @current_playlist_table_view.reloadData
        current_playlist_table_view.scrollRowToVisible(@playing_song)
        get_cover_art(song[:cover_art].split("/").last.split(".").first)
        @subsonic.scrobble(song[:id], @subsonic, :scrobble_response)
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
    
    def play_toggle_button(sender)
        play_toggle 
    end
    
    def play_toggle 
        if @current_playlist.length > 0
            if @playing_song_object.rate != 0
                @playing_song_object.stop
                @play_button.setImage(NSImage.imageNamed("Play"))
            else
                @playing_song_object.play 
                @play_button.setImage(NSImage.imageNamed("Pause"))
            end
        end
    end
    
    def play_previous_button(sender)
        play_previous
    end
    
    def play_previous
        if @playing_song != 0 && !@playing_song.nil? && @current_playlist.length > 1
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
        end
    end
    
    def volume_changed(sender)
        @volume = @volume_slider.floatValue
        @playing_song_object.setVolume(@volume)
    end
    
    def play_next 
        if @repeat_single == true
            @playing_song_object.setCurrentTime(QTTime.new(0,1,false))
            play_song
            NSLog "Repeat Single"
        elsif @repeat_all == true && @playing_song == @current_playlist.length - 1
            @playing_song = 0
            play_song
            NSLog "Repeat all"
        elsif @shuffle == true
            unless @current_playlist.length == 1
                current = @playing_song
                begin
                    @playing_song = rand(current_playlist.length)
                end while @playing_song == current
            end
            play_song
            NSLog "Shuffle"
        elsif !@playing_song.nil? && !@current_playlist[@playing_song + 1].nil?
            @playing_song += 1
            play_song
        end
    end
    
    def repeat_single(sender)
        if @repeat_single == true
            @repeat_single = false 
            sender.setState(NSOffState) 
        else 
            @repeat_single = true
            @repeat_all = false
            sender.setState(NSOnState)
            @repeat_all_menu_item.setState(NSOffState)
        end
    end
    
    def repeat_all(sender)
        if @repeat_all == true 
            @repeat_all = false
            sender.setState(NSOffState)
        else
            @repeat_all = true 
            @repeat_single = false
            sender.setState(NSOnState)
            @repeat_one_menu_item.setState(NSOffState)
        end
    end
    
    def repeat_off(sender)
        @repeat_one_menu_item.setState(NSOffState)
        @repeat_all_menu_item.setState(NSOffState)
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
    
    def decreaseVolume(sender)
        @volume < 0.1 ? @volume = 0.0 : @volume -= 0.1
        @playing_song_object.setVolume(@volume)
        @volume_slider.setFloatValue(@volume)
    end
    
    def increaseVolume(sender)
        @volume > 0.9 ? @volume = 1.0 : @volume += 0.1
        @playing_song_object.setVolume(@volume)
        @volume_slider.setFloatValue(@volume)
        @mute_menu_item.setState(NSOffState)
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
            sender.setState(NSOffState)
        else
            @shuffle = true
            sender.setState(NSOnState)
        end
    end
    
    def songEnded(notification)
		@playing_song_object.setCurrentTime(QTTime.new(0, 1, false))
        update_progress_bar(@progress_timer)
        @play_button.setImage(NSImage.imageNamed("Play"))
        play_next unless @current_playlist[@playing_song + 1].nil? && @repeat_all == false && @shuffle == false && @repeat_single == false
    end
    
    def loadStateChanged(notification)
        if @playing_song_object.attributeForKey(QTMovieLoadStateAttribute) == 100000
            @playing_song_object_progress.stopAnimation(nil)
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
            result = @playing_song_object.writeToFile(path, withAttributes:{QTMovieFlatten => true, QTMovieExport => true}, error:nil) unless File.exists?(path)
            if @current_playlist.length >= @playing_song + 2
                next_song = @current_playlist[@playing_song + 1]
                @subsonic.download_media(next_song[:cache_path], next_song[:id], @subsonic, :download_media_response)
                get_cover_art(next_song[:cover_art].split("/").last.split(".").first)
            end
		elsif @playing_song_object.attributeForKey(QTMovieLoadStateAttribute) == 20000
			#ready to play
            set_playing_cover_art
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
            end
        end
    end
end

