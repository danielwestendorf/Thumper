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
        if row < parent.songs.length
            return parent.current_playlist[row].valueForKey(column.identifier.to_sym)
        end
        nil
    end
    
end