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
        parent.add_to_current_playlist(parent.songs[row])
        parent.play_song if parent.current_playlist.length == 1
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
    
    def add_all_songs_to_current(sender)
        Dispatch::Queue.new('com.Thumper.playlist_thread').sync do
            parent.songs.each do |song|
                parent.add_to_current_playlist(song)
                parent.play_song if parent.current_playlist.length == 1
            end
        end
    end
    
    def update_songs(sender)
        parent.get_album_songs(parent.albums[parent.albums_table_view.selectedRow][:id]) if parent.albums.length > 0
    end
    
    def add_selected_to_playlist(sender)
        row = parent.songs_table_view.selectedRow
        row = 0 if row.nil?
        parent.add_to_current_playlist(parent.songs[row])
    end
end