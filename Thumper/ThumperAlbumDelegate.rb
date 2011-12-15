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
    
    def represented_objects
       parent.albums 
    end
    
    def numberOfRowsInTableView(tableView)
        parent.albums.count 
    end
    
    def tableView(tableView, setObjectValue:object, forTableColumn:column, row:row)
        @parent.albums[row][:rating] = object
        @parent.subsonic.rate(@parent.albums[row])
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
            return parent.albums[row].valueForKey(column.identifier.to_sym)
        end
        nil
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
