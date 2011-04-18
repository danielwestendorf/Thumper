#
#  ThumperCurrentPlaylistDelegate.rb
#  Thumper
#
#  Created by Daniel Westendorf on 4/4/11.
#  Copyright 2011 Daniel Westendorf. All rights reserved.
#


class ThumperCurrentPlaylistDelegate

    attr_accessor :parent
    
    def numberOfRowsInTableView(tableView)
        parent.current_playlist.count 
    end
    
    def tableView(tableView, objectValueForTableColumn:column, row:row)
        #NSLog "Asked for Current Playlist Row:#{row}, Column:#{column.identifier}"
        if row < parent.current_playlist.length
            if column.identifier == "indicator"
                return NSImage.imageNamed("Playing") if row == parent.playing_song
            else
                return parent.current_playlist[row].valueForKey(column.identifier.to_sym)
            end
        end
        nil
    end
    
    def awakeFromNib
        parent.current_playlist_table_view.doubleAction = 'double_click:'
        parent.current_playlist_table_view.target = self
    end

    def double_click(sender)
        @parent.playing_song = parent.current_playlist_table_view.selectedRow
        @parent.play_song
    end
    
    def clear_playlist(sender)
        @parent.current_playlist = []
        @parent.playing_song_object.stop
        @parent.playing_song = nil
        @parent.playing_song_object = QTMovie.alloc
        @parent.reload_current_playlist
        @parent.set_playing_info
        @parent.set_playing_cover_art
    end
    
    def remove_selected_from_playlist(sender)
        selected = parent.current_playlist_table_view.selectedRow
        if selected > -1
            @parent.current_playlist.delete_at(selected)
            @parent.reload_current_playlist
            @parent.play_song if selected == @parent.playing_song && @parent.current_playlist.length > 0
        end
    end
    
end