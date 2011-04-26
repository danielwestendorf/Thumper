#
#  ThumperPlaylistsDelegate.rb
#  Thumper
#
#  Created by Daniel Westendorf on 4/12/11.
#  Copyright 2011 Daniel Westendorf. All rights reserved.
#
class ThumperPlaylistsDelegate
    attr_accessor :parent, :confirmation_window
    
    def numberOfRowsInTableView(tableView)
        parent.playlists.count 
    end
    
    def tableView(tableView, objectValueForTableColumn:column, row:row)
        if row < parent.playlists.length
            return parent.playlists[row][:name] 
        end
        nil
    end
    
    def tableViewSelectionDidChange(notification)
        parent.playlist_songs = DB[:playlist_songs].join(:songs, :id => :song_id).filter(:playlist_id => parent.playlists[parent.playlists_table_view.selectedRow][:id]).all
        parent.reload_playlist_songs
        parent.get_playlist(parent.playlists[parent.playlists_table_view.selectedRow][:id])
    end
    
    def update_playlists(sender)
        parent.playlist_songs = []
        parent.reload_playlist_songs
        parent.get_playlists
    end
    
    def delete_playlist(sender)
        NSApp.beginSheet(confirmation_window,
                         modalForWindow:parent.main_window,
                         modalDelegate:self,
                         didEndSelector:nil,
                         contextInfo:nil)
        
    end
    
    def confrimed_delete_playlist(sender)
        NSApp.endSheet(confirmation_window)
        confirmation_window.orderOut(sender)
        row = parent.playlists_table_view.selectedRow
        id = parent.playlists[row][:id]
        parent.subsonic.delete_playlist(id, self, :delete_playlist_response)
        parent.playlists.delete_at(row)
        parent.playlist_songs = []
        parent.reload_playlists
        parent.reload_playlist_songs 
    end
    
    def canceled_delete_playlist(sender)
        NSApp.endSheet(confirmation_window)
        confirmation_window.orderOut(sender)
    end
    
    def delete_playlist_response(xml)
        if xml.class == NSXMLDocument
            NSLog "Playlist deleted from the server"
        else
            NSLog "There was an error deleting the playlist from the server #{xml}"
        end
    end
    
    
end
