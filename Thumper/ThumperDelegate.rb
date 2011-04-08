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
    attr_accessor :artists, :artist_indexes_table_view, :artist_count_label
    attr_accessor :artist_albums, :artist_albums_table_view, :album_count_label
    attr_accessor :album_songs, :album_songs_table_view, :album_songs_count_label
    attr_accessor :current_playlist, :current_playlist_table_view, :current_playlist_count_label
    
    def initialize
        @artists = []
        @artist_albums = []
        @album_songs = []
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
        @subsonic = SubsonicQuery.new(server_url, username, password)
        @subsonic.ping(self, :server_online, :server_offline) 
    end
    
    def hide_connection_info(sender)
        NSApp.endSheet(server_info_window)
        server_info_window.orderOut(sender)
        @subsonic = SubsonicQuery.new(server_url, username, password)
        @subsonic.ping(self, :server_online, :server_offline)
    end
    
    def server_online(response)
        @status_label.stringValue = response 
        self.get_artist_indexes
        NSLog response
    end
    
    def server_offline(message)
        @status_label.stringValue = "Offline"
        NSLog message.to_s
    end

    def get_artist_indexes
        @artists = []
        DB[:artists].all.each do |artist|
            @artists << {:name => artist[:name], :id => artist[:subsonic_id]}
        end
        @artist_albums.count != 1 ? word = " Artists" : word = " Artist"
        @artist_count_label.stringValue = @artists.count.to_s + word
        @artist_indexes_table_view.reloadData
        @subsonic.getIndexes(self, :update_artists_indexes)
    end
    
    def update_artists_indexes(response)
        @artists = []
        NSLog "Updating artist index"
        response.last["index"].each do |index|
            index["artist"].each do |artist| 
                @artists << {:name => artist["name"], :id => artist["id"]}
            end
        end
        NSLog "Updating artist index complete. #{@artists.length} Artists"
        @artist_albums.count != 1 ? word = " Artists" : word = " Artist"
        @artist_count_label.stringValue = @artists.count.to_s + word
        @artist_indexes_table_view.reloadData
        NSLog "Persisting Aritsts to the DB"
        if DB[:artists].all.count < 1
            DB.transaction do
                @artists.each {|a| DB[:artists].insert(:name => a[:name], :subsonic_id => a[:id]) } 
            end
        end
    end
    
    
    def get_artist_albums(id)
        @subsonic.getMusicDirectory(self, :update_artist_albums, {:id => id})
        NSLog "Getting albums for #{id}"
    end
    
    def update_artist_albums(response)
       @artist_albums = []
        if response.last["child"].class == Hash
            album = response.last["child"]
            @artist_albums << {:id => album["id"], :title => album["title"], :cover_art => album["coverArt"]} if album["isDir"] == "true"
        else
            response.last["child"].each do |album|
                @artist_albums << {:id => album["id"], :title => album["title"], :cover_art => album["coverArt"]} if album["isDir"] == "true"
            end 
        end
        NSLog "Update of artist albums complete. #{@artist_albums.length} albums"
        @artist_albums.count != 1 ? word = " Albums" : word = " Album"
        @album_count_label.stringValue = @artist_albums.count.to_s + word
        @artist_albums_table_view.reloadData
        @artist_albums_table_view.enabled = true

    end
    
    def get_album_songs(id)
        @subsonic.getMusicDirectory(self, :update_album_songs, {:id => id})
        NSLog "Getting songs for #{id}"
    end
    
    def update_album_songs(response)
        @album_songs = []
        if response.last["child"].class == Hash
            song = response.last["child"]
            @album_songs << {:id => song["id"], :title => song["title"], :duration => format_time(song["duration"].to_i), :track => song["track"], :artist => song["artist"], :album => song["album"]} if song["isDir"] == "false" && song["isVideo"] == "false"
        else
            response.last["child"].each do |song|
                @album_songs << {:id => song["id"], :title => song["title"], :duration => format_time(song["duration"].to_i), :track => song["track"], :artist => song["artist"], :album => song["album"]} if song["isDir"] == "false" && song["isVideo"] == "false"
            end 
        end
        NSLog "Update of album songs complete. #{@album_songs.length} songs"
        @album_songs.count != 1 ? word = " Songs" : word = " Song"
        @album_songs_count_label.stringValue = @album_songs.count.to_s + word
        @album_songs_table_view.reloadData
        @album_songs_table_view.enabled = true
        
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

