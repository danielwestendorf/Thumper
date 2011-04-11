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
        NSLog "Asked for Current Playlist Row:#{row}, Column:#{column.identifier}"
        if row < parent.current_playlist.length
            return parent.current_playlist[row].valueForKey(column.identifier.to_sym)
        end
        nil
    end
    
    def awakeFromNib
        parent.current_playlist_table_view.doubleAction = 'double_click:'
        parent.current_playlist_table_view.target = self
    end
    
    def double_click(sender)
        @parent.playing_song = @parent.current_playlist[parent.current_playlist_table_view.selectedRow]
        id = @parent.playing_song[:id]
        Dispatch::Queue.new('com.thumper.player').async do
            url = NSURL.alloc.initWithString("#{@parent.server_url}/rest/stream.view?u=#{@parent.username}&p=#{@parent.password}&v=1.4.0&c=Thumper&v=1.4.0&f=xml&id=#{id}")
            NSLog "Streaming song #{id}"
            @parent.playing_song_object.stop if @parent.playing_song_object
            @parent.playing_song_object = QTMovie.alloc.initWithURL(url, error:nil)
            @parent.playing_song_object.autoplay
        end
    end
    
end