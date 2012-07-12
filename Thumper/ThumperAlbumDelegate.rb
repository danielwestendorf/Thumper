#
#  ThumperArtistAlbumDelegate.rb
#  Thumper
#
#  Created by Daniel Westendorf on 4/3/11.
#  Copyright 2011 Daniel Westendorf. All rights reserved.
#

class ThumperAlbumDelegate
    attr_accessor :parent, :share_enabled, :rate_enabled
    
    def initialize
        @share_enabled = true
        @rate_enabled = true
    end
    
    def rate_item(sender)
        object = sender.representedObject
        parent.albums[object[:row]][:rating] = object[:rating]
        @parent.subsonic.rate(object)
        @parent.albums_table_view.reloadData
    end
    
    def awakeFromNib
        parent.albums_table_view.doubleAction = 'double_click:'
        parent.albums_table_view.target = self 
    end
    
    def represented_objects
       parent.albums 
    end
    
    def double_click(sender)
        return if parent.songs.length < 1
        add_album_to_playlist(sender)
    end
    
    def numberOfRowsInTableView(tableView)
        parent.albums.count 
    end
    
    def tableView(tableView, setObjectValue:object, forTableColumn:column, row:row)
        if  @parent.rating_enabled
            @parent.albums[row][:rating] = object
            @parent.subsonic.rate(@parent.albums[row]) 
        else
            NSLog "Cannot save rating change, Rating and Commenting is not enabled for user #{@parent.username}"
        end
    end
    
    def tableView(tableView, objectValueForTableColumn:column, row:row)
        #NSLog "Asked for Album Row:#{row}, Column:#{column.identifier}"
        if parent.quick_playlists_table_view.selectedRow > -1 && row.to_f / parent.albums.length.to_f > 0.8 && parent.albums.length > 0 && parent.albums.length > parent.qp_offset#fetch the next bunch of rows
            #get_more
        end
        if row < parent.albums.length
            if column.identifier.to_s == "cover_art"
                image = parent.albums[row].valueForKey(column.identifier.to_sym)
                @parent.get_cover_art(@parent.albums[row][:coverArt]) unless @parent.albums[row][:coverArt].nil? || File.exists?(@parent.albums[row][:cover_art]) 
                return NSImage.alloc.initWithContentsOfFile(image) if File.exists?(image)
                return NSImage.imageNamed("album") 
            elsif column.identifier.to_s == "rating"
                return @parent.albums[row][:rating].to_i
            end
            return album_name(row)
        end
        nil
    end
    
    def album_name(row)
        if parent.quick_playlists_table_view.selectedRow > -1
           "#{parent.albums[row].valueForKey(:artist)}\r\n#{parent.albums[row].valueForKey(:title)}"
        else
            parent.albums[row].valueForKey(:title)
        end
    end
    
    def tableView(tableView, heightOfRow:row)
        string = album_name(row)
        column = tableView.tableColumns[1]
        columnDataCell = NSCell.alloc.initTextCell(string)
        
        height = columnDataCell.cellSizeForBounds(NSMakeRect(0.0, 0.0, column.width, Float::MAX)).height + 20.0
        height > 60.0 ? height : 60.0
    end
    
    def tableViewSelectionDidChange(notification)
        #NSLog "Album selection did change!"
        parent.songs = []
        parent.songs_table_view.enabled = false
        parent.songs_table_view.reloadData
        parent.get_album_songs(parent.albums[parent.albums_table_view.selectedRow][:id]) if parent.albums.length > 0
        #NSLog "Selected Album #{parent.albums[parent.albums_table_view.selectedRow]}"
    end
    
    def add_album_to_playlist(sender)
        @parent.db_queue.sync do
            parent.songs.each do |song|
                parent.add_to_current_playlist(song, true)
            end
        end
    end
    
    def get_more
        @parent.qp_offset += 50
        #NSLog "Getting more!"
        parent.get_quick_playlist({:type => parent.quick_playlists[parent.quick_playlists_table_view.selectedRow][1], :append => true, :offset => @parent.qp_offset}) 
    end
end
