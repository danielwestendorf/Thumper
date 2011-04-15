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
        parent.current_playlist << parent.playlist_songs[row] unless parent.current_playlist.include?(parent.playlist_songs[row])
        NSLog "#{parent.current_playlist}"
        parent.current_playlist.count != 1 ? word = " Songs" : word = " Song"
        parent.current_playlist_count_label.stringValue = parent.current_playlist.count.to_s + word
        parent.current_playlist_table_view.reloadData
        parent.current_playlist_table_view.scrollRowToVisible(parent.current_playlist.length - 1)
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
    
end

