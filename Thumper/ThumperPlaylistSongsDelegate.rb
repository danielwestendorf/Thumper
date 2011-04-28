#
#  ThumperPlaylistSongsDelegate.rb
#  Thumper
#
#  Created by Daniel Westendorf on 4/12/11.
#  Copyright 2011 Daniel Westendorf. All rights reserved.
#
class ThumperPlaylistSongsDelegate
    attr_accessor :parent
    
    def awakeFromNib
        parent.playlist_songs_table_view.doubleAction = 'double_click:'
        parent.playlist_songs_table_view.target = self
    end
    
    def double_click(sender)
        row = parent.playlist_songs_table_view.selectedRow
        parent.add_to_current_playlist(parent.playlist_songs[row])
    end
    
    def numberOfRowsInTableView(tableView)
        parent.playlist_songs.count 
    end
    
    def tableView(tableView, objectValueForTableColumn:column, row:row)
        #NSLog "Asked for Song Row:#{row}, Column:#{column.identifier}"
        if row < parent.playlist_songs.length
            return parent.playlist_songs[row].valueForKey(column.identifier.to_sym)
        end
        nil
    end
    
    def add_playlist_to_current(sender)
        
        Dispatch::Queue.new('com.Thumper.playlist_thread').async do
            parent.playlist_songs.each do |song|
                parent.current_playlist << song
                DB[:playlist_songs].insert(:name => "Current", :playlist_id => "666current666", :song_id => song[:id])
            end
            parent.reload_current_playlist
            if parent.current_playlist.length == 1
                parent.playing_song = 0
                parent.play_song
            elsif parent.playing_song == parent.current_playlist.length - 2
                next_song = parent.current_playlist[@parent.playing_song + 1]
                unless File.exists?(next_song[:cache_path])
                    parent.subsonic.download_media(next_song[:cache_path], next_song[:id], parent.subsonic, :download_media_response)
                    parent.get_cover_art(next_song[:cover_art].split("/").last.split(".").first)
                end
            end
        end
    end
    
    def update_songs(sender)
        row = parent.playlists_table_view.selectedRow
        parent.get_playlist(parent.playlists[row][:id]) if parent.playlists.length > 0
    end
    
    def add_song_to_current(sender)
        row = parent.playlist_songs_table_view.selectedRow
        parent.add_to_current_playlist(parent.playlist_songs[row])
        parent.play_song if parent.current_playlist.length == 1
    end
    
end

