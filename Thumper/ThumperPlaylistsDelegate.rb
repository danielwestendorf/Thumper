#
#  ThumperPlaylistsDelegate.rb
#  Thumper
#
#  Created by Daniel Westendorf on 4/12/11.
#  Copyright 2011 Daniel Westendorf. All rights reserved.
#
class ThumperPlaylistsDelegate
    attr_accessor :parent
    
    def numberOfRowsInTableView(tableView)
        parent.playlists.count 
    end
    
    def tableView(tableView, objectValueForTableColumn:column, row:row)
        if row < parent.playlists.length
            return parent.playlists[row][:name] 
        end
        nil
    end
    
    def tableViewSelectionDidChange(notification)
        parent.playlist_songs = DB[:playlist_songs].join(:songs, :id => :song_id).filter(:playlist_id => parent.playlists[parent.playlists_table_view.selectedRow][:id]).all
        parent.reload_playlist_songs
        parent.get_playlist(parent.playlists[parent.playlists_table_view.selectedRow][:id])
    end
    
    def update_playlists(sender)
        parent.playlist_songs = []
        parent.reload_playlist_songs
        parent.get_playlists
    end
end
