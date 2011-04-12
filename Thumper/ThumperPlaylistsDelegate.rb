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
        #NSLog "Asked for Artist Row:#{row}, Column:#{column.identifier}"
        if row < parent.playlists.length
            return parent.playlists[row][:name] 
        end
        nil
    end
    
    def tableViewSelectionDidChange(notification)
        parent.playlist_songs = []
        parent.playlist_songs_table_view.enabled = false
        parent.get_playlist(parent.playlists[parent.playlists_table_view.selectedRow][:id])
        #NSLog "Selected Artist #{parent.artist_indexes_table_view.selectedRow}"
    end
    
end
