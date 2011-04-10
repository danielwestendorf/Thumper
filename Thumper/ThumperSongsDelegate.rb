#
#  ThumperAlbumSongsDelegate.rb
#  Thumper
#
#  Created by Daniel Westendorf on 4/3/11.
#  Copyright 2011 Daniel Westendorf. All rights reserved.
#


class ThumperSongsDelegate
    attr_accessor :parent
    
    def awakeFromNib
        parent.songs_table_view.doubleAction = 'double_click:'
        parent.songs_table_view.target = self
    end
    
    def double_click(sender)
        row = parent.songs_table_view.selectedRow
        NSLog "Adding #{parent.songs[row][:title]} to the current playlist" unless parent.current_playlist.include?(parent.songs[row])
        parent.current_playlist << parent.songs[row] unless parent.current_playlist.include?(parent.songs[row])
        parent.current_playlist.count != 1 ? word = " Songs" : word = " Song"
        parent.current_playlist_count_label.stringValue = parent.current_playlist.count.to_s + word
        parent.current_playlist_table_view.reloadData
    end
    
    def numberOfRowsInTableView(tableView)
        parent.songs.count 
    end
    
    def tableView(tableView, objectValueForTableColumn:column, row:row)
        #NSLog "Asked for Song Row:#{row}, Column:#{column.identifier}"
        if row < parent.songs.length
            return parent.songs[row].valueForKey(column.identifier.to_sym)
        end
        nil
    end
    
end