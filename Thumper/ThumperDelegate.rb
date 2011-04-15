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
    attr_accessor :playing_song_object, :playing_song
    attr_accessor :artist_reload_button, :album_reload_button, :song_reload_button
    attr_accessor :playlists, :playlists_table_view, :playlist_songs, :playlist_songs_table_view, :playlists_count_label, :playlist_songs_count_label
    attr_accessor :playlists_progress, :playlist_songs_progress
	attr_accessor :playing_song_progress_view, :play_toggle_button, :play_previous_button, :play_next_button, :playing_cover_art, :playing_time_elapsed, :playing_time_remaining
    
    def initialize
        @artists = []
        @albums = []
        @songs = []
        @playlists = []
        @playlist_songs = []
        @current_playlist_id = DB[:playlists].where(:name => "Thumper Current").all.first
        @current_playlist = []
        @playing_song_object = QTMovie.alloc
        @server_url = NSUserDefaults.standardUserDefaults['thumper.com.server_url']
        @username = NSUserDefaults.standardUserDefaults['thumper.com.username']
        @password = NSUserDefaults.standardUserDefaults['thumper.com.password']
    end
    
    def applicationDidFinishLaunching(a_notification)
        @username.nil? || @password.nil? || @server_url.nil? ? show_server_info_modal : setup_subsonic_conneciton
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
        @server_url = server_url_field.stringValue
        @username = username_field.stringValue
        @password = password_field.stringValue
        NSUserDefaults.standardUserDefaults['thumper.com.server_url'] = @server_url
        NSUserDefaults.standardUserDefaults['thumper.com.username'] = @username
        NSUserDefaults.standardUserDefaults['thumper.com.password'] = @password
        NSUserDefaults.standardUserDefaults.synchronize

        NSApp.endSheet(server_info_window)
        server_info_window.orderOut(sender)
        if server_url.blank? || username.blank? || password.blank?
            show_server_info_modal
        else
            setup_subsonic_conneciton
        end
    end
    
    def setup_subsonic_conneciton
        NSLog "Connecting to subsonic"
        @subsonic = Subsonic.new(self, server_url, username, password)
        @subsonic.ping(@subsonic, :ping_response)
        get_artist_indexes
        get_playlists
    end
    
    def hide_connection_info(sender)
        NSApp.endSheet(server_info_window)
        server_info_window.orderOut(sender)
        @subsonic = SubsonicQuery.new(server_url, username, password)
        @subsonic.ping(self, :server_online, :server_offline)
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
        @playlist_songs = []
        @playlist_songs_table_view.enabled = false
        reload_playlist_songs
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
    
    def get_artist_albums(id)
        @albums_progress.startAnimation(nil)
        @albums = []
        DB[:albums].filter(:artist_id => id).all.each do |album|
            @albums << {:id => album[:id], :title => album[:title], :cover_art => album[:cover_art], :artist_id => album[:artist_id]} 
        end
        reload_albums
        @subsonic.albums(id, @subsonic, :albums_response)
        NSLog "Getting albums for #{id}"
    end
        
    def get_album_songs(id)
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
        NSLog "Getting songs for #{id}"
    end
    
    def get_cover_art(id)
        @subsonic.cover_art(id, @subsonic, :image_response)
        NSLog "Got cover art"
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
        Dispatch::Queue.new('com.thumper.player').async do
            song = @current_playlist[@playing_song]
            NSLog "#{song[:path]}"
            if File.exists?(song[:cache_path])
                @playing_song_object.stop if @playing_song_object
                @playing_song_object = QTMovie.alloc.initWithFile(song[:cache_path], error:nil)
                @playing_song_object.autoplay
                NSLog "Playing song from cache"
            else
                url = NSURL.alloc.initWithString("#{@server_url}/rest/stream.view?u=#{@username}&p=#{@password}&v=1.4.0&c=Thumper&v=1.4.0&f=xml&id=#{song[:id]}")
                NSLog "Streaming song"
                @playing_song_object.stop if @playing_song_object
                @playing_song_object = QTMovie.alloc.initWithURL(url, error:nil)
                NSNotificationCenter.defaultCenter.addObserver(self, selector:'loadStateChanged:', name:QTMovieLoadStateDidChangeNotification, object:@playing_song_object)
                NSNotificationCenter.defaultCenter.addObserver(self, selector:'volumeDidChange:', name:QTMovieVolumeDidChangeNotification, object:@playing_song_object)
                NSNotificationCenter.defaultCenter.addObserver(self, selector:'timeDidChange:', name:QTMovieTimeDidChangeNotification, object:@playing_song_object)
                NSNotificationCenter.defaultCenter.addObserver(self, selector:'songEnded:', name:QTMovieDidEndNotification, object:@playing_song_object)
                @playing_song_object.autoplay 
            end
        end
        @progress_timer = NSTimer.scheduledTimerWithTimeInterval 0.1,
            target: self,
            selector: 'update_progress_bar:',
            userInfo: nil,
            repeats: true
        set_playing_cover_art
    end
    
    def set_playing_cover_art
        image = @current_playlist[@playing_song][:cover_art]
        if File.exists?(image)
            @playing_cover_art.setImage(NSImage.alloc.initWithContentsOfFile(image))
        else
            @playing_cover_art.setImage(NSImage.imageNamed("album"))
        end 
    end
    
    def play_toggle_button(sender)
        play_toggle 
    end
    
    def play_toggle 
        @playing_song_object.rate != 0 ? @playing_song_object.stop : @playing_song_object.play 
    end
    
    def play_previous_button(sender)
        play_previous
    end
    
    def play_previous
        unless @playing_song == 0
            @playing_song -= 1
            play_song
        end
    end
    
    def play_next_button(sender)
        play_next 
    end
    
    def play_next 
        unless @playing_song + 2 > @current_playlist.length
            @playing_song += 1
            play_song
        end
    end
    
    def volumeDidChange(notificaiton)
        NSLog "Volume Changed"
    end
    
    def timeDidChange(notification)
        NSLog "Time Changed"
    end
    
    def songEnded(notification)
		@progress_timer.invalidate
		@playing_song_progress_view.progressPercent = 0.00
		@playing_song_progress_view.display
        NSLog "Song is over Go to the next nigger"
        play_next
    end
    
    def loadStateChanged(notification)
        if @playing_song_object.attributeForKey(QTMovieLoadStateAttribute) == 100000
            path = @current_playlist[@playing_song][:cache_path]
            path_step = "/"
            split_path = path.split('/')
            split_path.delete_at(0)
            split_path.delete_at(split_path.length - 1)
            split_path.each do |dir|
                path_step << dir
                if !File.exists?(path_step)
                    Dir.mkdir(path_step)
                    NSLog "Create path #{path_step}" 
                end
                path_step << '/'
            end
            result = @playing_song_object.writeToFile(path, withAttributes:{QTMovieFlatten => true, QTMovieExport => true}, error:nil) unless File.exists?(path)
            NSLog "Saving of file resulted in #{result}"
		elsif @playing_song_object.attributeForKey(QTMovieLoadStateAttribute) == 20000
			#ready to play
            set_playing_cover_art
        end
        NSLog "Change in the load state"
    end
    
    def update_progress_bar(timer)
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

