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
        parent.play_song if parent.current_playlist.length == 1
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
        Dispatch::Queue.new('com.Thumper.playlist_thread').sync do
            @parent.playlist_songs.each do |song|
                parent.add_to_current_playlist(song)
                parent.play_song if parent.current_playlist.length == 1
            end
        end
    end
    
    def update_songs(sender)
        parent.get_playlist(parent.playlists[parent.playlists_table_view.selectedRow][:id])
    end
    
    def add_song_to_current(sender)
        row = parent.playlist_songs_table_view.selectedRow
        parent.add_to_current_playlist(parent.playlist_songs[row])
        parent.play_song if parent.current_playlist.length == 1
    end
    
end

