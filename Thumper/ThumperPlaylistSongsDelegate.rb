#
#  ThumperPlaylistSongsDelegate.rb
#  Thumper
#
#  Created by Daniel Westendorf on 4/12/11.
#  Copyright 2011 Daniel Westendorf. All rights reserved.
#
class ThumperPlaylistSongsDelegate
    attr_accessor :parent, :share_enabled, :rate_enabled
    
    def initialize
        @share_enabled = true
        @rate_enabled = true
    end
    
    def represented_objects
        parent.playlist_songs 
    end
    
    def rate_item(sender)
        object = sender.representedObject
        parent.playlist_songs[object[:row]][:rating] = object[:rating]
        @parent.subsonic.rate(object)
        @parent.playlist_songs_table_view.reloadData
    end
    
    def awakeFromNib
        parent.playlist_songs_table_view.doubleAction = 'double_click:'
        parent.playlist_songs_table_view.target = self
    end
    
    def double_click(sender)
        row = parent.playlist_songs_table_view.selectedRow
        parent.add_to_current_playlist(parent.playlist_songs[row])
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
    
    def tableView(aView, writeRowsWithIndexes:rowIndexes, toPasteboard:pboard)
        songs_array = []
        rowIndexes.each do |row|
            songs_array << parent.playlist_songs[row]
        end
        pboard.setString(songs_array.reverse.to_yaml, forType:"Songs")
        return true
    end
    
    def select_all
        range = NSMakeRange(0, parent.playlist_songs.length)
        indexes = NSIndexSet.alloc.initWithIndexesInRange(range)
        parent.playlist_songs_table_view.selectRowIndexes(indexes, byExtendingSelection:true)
    end
    
    def pressed_delete
        return nil
    end
    
    def update_songs(sender)
        row = parent.playlists_table_view.selectedRow
        parent.get_playlist(parent.playlists[row][:id]) if parent.playlists.length > 0
    end
    
    def add_song_to_current(sender)
        rows = parent.playlist_songs_table_view.selectedRowIndexes
        row_collection = []
        if rows.count > 0
            rows.each do |row|
                row_collection << row
            end
            row_collection.reverse.each {|r| parent.add_to_current_playlist(parent.playlist_songs[r], false) }
        else
            parent.playlist_songs.each do |song|
                parent.add_to_current_playlist(song, false)
            end
        end
        parent.reload_current_playlist
        parent.play_song if parent.current_playlist.length == 1
    end
    
end

