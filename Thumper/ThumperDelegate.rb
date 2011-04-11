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
    attr_accessor :artists, :all_artists, :artist_indexes_table_view, :artist_count_label
    attr_accessor :albums, :albums_table_view, :album_count_label
    attr_accessor :songs, :songs_table_view, :songs_count_label
    attr_accessor :current_playlist, :current_playlist_table_view, :current_playlist_count_label
    attr_accessor :playing_song_object, :playing_song
    attr_accessor :artist_reload_button, :album_reload_button, :song_reload_button
    
    def initialize
        @artists = []
        @albums = []
        @songs = []
        @current_playlist_id = DB[:playlists].where(:name => "Thumper Current").all.first
        @current_playlist = []
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
    end
    
    def hide_connection_info(sender)
        NSApp.endSheet(server_info_window)
        server_info_window.orderOut(sender)
        @subsonic = SubsonicQuery.new(server_url, username, password)
        @subsonic.ping(self, :server_online, :server_offline)
    end
    
    def get_artist_indexes
        @artists = []
        DB[:artists].all.each do |artist|
            @artists << {:name => artist[:name], :id => artist[:id]}
        end
        @all_artists = @artists
        reload_artists
        @subsonic.artists(@subsonic, :artists_response)
    end
    
    def reload_artists
        @artists.count != 1 ? word = " Artists" : word = " Artist"
        @artist_count_label.stringValue = @artists.count.to_s + word
        albums_table_view.reloadData
        songs_table_view.reloadData
        artist_indexes_table_view.reloadData
    end
    
    
    def get_artist_albums(id)
        @albums = []
        DB[:albums].filter(:artist_id => id).all.each do |album|
            @albums << {:id => album[:id], :title => album[:title], :cover_art => album[:cover_art], :artist_id => album[:artist_id]} 
        end
        @albums.count != 1 ? word = " Albums" : word = " Album"
        @album_count_label.stringValue = @albums.count.to_s + word
        @albums_table_view.reloadData
        @albums_table_view.enabled = true
        @subsonic.albums(id, @subsonic, :albums_response)
        NSLog "Getting albums for #{id}"
    end
        
    def get_album_songs(id)
        @songs = []
        DB[:songs].filter(:album_id => id).all.each do |song|
            @songs << {:id => song[:id], :title => song[:title], :duration => format_time(song[:duration].to_i), :track => song[:track], 
                :artist => song[:artist], :album => song[:album], :bitrate => song[:bitrate], :year => song[:year], :genre => song[:genre],
                :size => song[:size], :suffix => song[:suffix], :album_id => song[:ablum_id], :cover_art => song[:cover_art], 
                :path => song[:path]} 
        end
        @songs.count != 1 ? word = " Songs" : word = " Song"
        @songs_count_label.stringValue = @songs.count.to_s + word
        @songs_table_view.reloadData
        @songs_table_view.enabled = true
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
end

