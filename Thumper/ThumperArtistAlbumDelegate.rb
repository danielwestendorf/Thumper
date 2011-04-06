#
#  ThumperArtistAlbumDelegate.rb
#  Thumper
#
#  Created by Daniel Westendorf on 4/3/11.
#  Copyright 2011 Daniel Westendorf. All rights reserved.
#

class ThumperArtistAlbumDelegate
    attr_accessor :parent
    
    def awakeFromNib
        #parent.artist_albums_table_view.doubleAction = 'double_click:'
        #parent.artist_albums_table_view.target = self
    end
    
    def numberOfRowsInTableView(tableView)
        parent.artist_albums.count 
    end
    
    def tableView(tableView, objectValueForTableColumn:column, row:row)
        #NSLog "Asked for Album Row:#{row}, Column:#{column.identifier}"
        if row < parent.artist_albums.length
            return parent.artist_albums[row].valueForKey(column.identifier.to_sym)
        end
        nil
    end
    
    def tableViewSelectionDidChange(notification)
        parent.album_songs = []
        parent.album_songs_table_view.enabled = false
        parent.album_songs_table_view.reloadData
        parent.get_album_songs(parent.artist_albums[parent.artist_albums_table_view.selectedRow][:id]) if parent.artist_albums.length > 0
        NSLog "Selected Artist #{parent.artist_albums_table_view.selectedRow}"
    end

end
