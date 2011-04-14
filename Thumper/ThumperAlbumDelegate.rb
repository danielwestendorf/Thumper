#
#  ThumperArtistAlbumDelegate.rb
#  Thumper
#
#  Created by Daniel Westendorf on 4/3/11.
#  Copyright 2011 Daniel Westendorf. All rights reserved.
#

class ThumperAlbumDelegate
    attr_accessor :parent
    
    def numberOfRowsInTableView(tableView)
        parent.albums.count 
    end
    
    def tableView(tableView, objectValueForTableColumn:column, row:row)
        #NSLog "Asked for Album Row:#{row}, Column:#{column.identifier}"
        if row < parent.albums.length
            if column.identifier.to_s == "cover_art"
                image = parent.albums[row].valueForKey(column.identifier.to_sym)
                return NSImage.alloc.initWithContentsOfFile(image) if File.exists?(image)
                return NSImage.imageNamed("album") 
            end
            return parent.albums[row].valueForKey(column.identifier.to_sym)
        end
        nil
    end
    
    def tableViewSelectionDidChange(notification)
        parent.songs = []
        parent.songs_table_view.enabled = false
        parent.songs_table_view.reloadData
        parent.get_album_songs(parent.albums[parent.albums_table_view.selectedRow][:id]) if parent.albums.length > 0
        #NSLog "Selected Artist #{parent.albums_table_view.selectedRow}"
    end

end
