#
#  ThumperAlbumSongsDelegate.rb
#  Thumper
#
#  Created by Daniel Westendorf on 4/3/11.
#  Copyright 2011 Daniel Westendorf. All rights reserved.
#


class ThumperSongsDelegate
    attr_accessor :parent, :share_enabled, :rate_enabled
    
    def awakeFromNib
        parent.songs_table_view.doubleAction = 'double_click:'
        parent.songs_table_view.target = self
        @share_enabled = true
        @rate_enabled = true
    end
    
    def rate_item(sender)
        object = sender.representedObject
        parent.songs[object[:row]][:rating] = object[:rating]
        @parent.subsonic.rate(object)
        @parent.songs_table_view.reloadData
    end
    
    def represented_objects
        parent.songs 
    end
    
    def double_click(sender)
        row = parent.songs_table_view.selectedRow
        parent.add_to_current_playlist(parent.songs[row])
    end
    
    def numberOfRowsInTableView(tableView)
        parent.songs.count 
    end
    
    def tableView(tableView, setObjectValue:object, forTableColumn:column, row:row)
        if @parent.rating_enabled
            @parent.songs[row][:rating] = object
            @parent.subsonic.rate(@parent.songs[row])
        else
            NSLog "Cannot save rating change, Rating and Commenting is not enabled for user #{@parent.username}"
        end
    end
    
    def tableView(aView, writeRowsWithIndexes:rowIndexes, toPasteboard:pboard)
        songs_array = []
        rowIndexes.each do |row|
            songs_array << parent.songs[row]
        end
        pboard.setString(songs_array.reverse.to_yaml, forType:"Songs")
        return true
    end
    
    def tableView(tableView, objectValueForTableColumn:column, row:row)
        #NSLog "Asked for Song Row:#{row}, Column:#{column.identifier}"
        if row < parent.songs.length
            if column.identifier.to_s == "rating"
                return @parent.songs[row][:rating].to_i 
            else
                return parent.songs[row].valueForKey(column.identifier.to_sym)
            end
        end
        nil
    end
    
    def select_all
        range = NSMakeRange(0, parent.songs.length)
        indexes = NSIndexSet.alloc.initWithIndexesInRange(range)
        parent.songs_table_view.selectRowIndexes(indexes, byExtendingSelection:true)
    end
    
    def pressed_delete
        return nil
    end
    
    def update_songs(sender)
        parent.get_album_songs(parent.albums[parent.albums_table_view.selectedRow][:id]) if parent.albums.length > 0
    end
    
    def add_selected_to_playlist(sender)
        rows = parent.songs_table_view.selectedRowIndexes
        row_collection = []
        if rows.count > 0
            rows.each do |row|
                row_collection << row
            end
            row_collection.reverse.each {|r| parent.add_to_current_playlist(parent.songs[r], false)}
        else
            parent.songs.each do |song|
               parent.add_to_current_playlist(song, false) 
            end
        end
        parent.reload_current_playlist
    end
end