#
#  ThumperArtistIndexDelegate.rb
#  Thumper
#
#  Created by Daniel Westendorf on 4/3/11.
#  Copyright 2011 Daniel Westendorf. All rights reserved.
#
class ThumperArtistIndexDelegate
    attr_accessor :parent
    
    def numberOfRowsInTableView(tableView)
        parent.artists.count 
    end
    
    def tableView(tableView, objectValueForTableColumn:column, row:row)
        #NSLog "Asked for Artist Row:#{row}, Column:#{column.identifier}"
        if row < parent.artists.length
           return parent.artists[row][:name] 
        end
        nil
    end
    
    def tableViewSelectionDidChange(notification)
        parent.albums = []
        parent.albums_table_view.enabled = false
        parent.albums_table_view.reloadData
        parent.get_artist_albums(parent.artists[parent.artist_indexes_table_view.selectedRow][:id])
        #NSLog "Selected Artist #{parent.artist_indexes_table_view.selectedRow}"
    end

end