#
#  ThumperArtistIndexDelegate.rb
#  Thumper
#
#  Created by Daniel Westendorf on 4/3/11.
#  Copyright 2011 Daniel Westendorf. All rights reserved.
#
class ThumperArtistIndexDelegate
    attr_accessor :parent
    attr_accessor :filter_input
    
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
        #NSLog "Artist Selection did change!"
        if parent.artist_indexes_table_view.selectedRow > -1
            parent.quick_playlists_table_view.deselectAll(nil) 
            parent.album_reload_button.setAction("update_albums:")
            parent.albums = []
            parent.songs = []
            parent.albums_table_view.enabled = false
            parent.songs_table_view.enabled = false
            parent.reload_albums
            parent.reload_songs
            parent.get_artist_albums(parent.artists[parent.artist_indexes_table_view.selectedRow][:id])
            
            #NSLog "Selected Artist #{parent.artist_indexes_table_view.selectedRow}, #{parent.artists[parent.artist_indexes_table_view.selectedRow][:id]}"
        end
    end
    
    def textInputOnEnterPressed(sender)
        #NSLog "Filtering artists by #{filter_input.stringValue}"
        filter = filter_input.stringValue.downcase.strip
        unless filter.empty?
            new_artists = []
            parent.all_artists.each {|a| new_artists << a unless a[:name].downcase.scan(filter).empty? }
            parent.artists = new_artists
            parent.get_artist_albums(new_artists.first[:id]) if new_artists.length == 1
        else
            parent.artists = parent.all_artists
        end
        parent.albums = []
        parent.songs = []
        parent.reload_artists
    end
    
    def update_artists(sender)
        parent.get_artist_indexes
    end

end