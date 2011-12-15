#
#  ThumperPlaylistsDelegate.rb
#  Thumper
#
#  Created by Daniel Westendorf on 4/12/11.
#  Copyright 2011 Daniel Westendorf. All rights reserved.
#
class ThumperPlaylistsDelegate
    attr_accessor :parent, :confirmation_window, :share_enabled, :rate_enabled
    
    def initialize
        @share_enabled = false
        @rate_enabled = false
    end
    
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
        if parent.playlists_table_view.selectedRow > -1
            parent.playlist_songs = DB[:playlist_songs].join(:songs, :id => :song_id).filter(:playlist_id => parent.playlists[parent.playlists_table_view.selectedRow][:id]).all
            parent.playlist_songs_reload_button.setTarget(self)
            parent.playlist_songs_reload_button.setAction("update_playlists:")
            parent.smart_playlists_table_view.deselectAll(nil)
            parent.reload_playlist_songs
            parent.get_playlist(parent.playlists[parent.playlists_table_view.selectedRow][:id])
        end
    end
    
    def update_playlists(sender)
        parent.playlist_songs = []
        parent.reload_playlist_songs
        parent.get_playlists
    end
    
    def delete_playlist(sender)
        confirm_delete
    end
    
    def select_all
        return nil
    end
    
    def pressed_delete
        confirm_delete
    end
    
    def confirm_delete
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
    
    def delete_playlist_response(xml, options)
        g = Growl.new("Thumper", ["notification"])
        if xml.class == NSXMLDocument && xml.nodesForXPath('subsonic-response', error:nil).first.attributeForName(:status).stringValue == "ok"
            #NSLog "Playlist deleted from the server"
            g.notify("notification", "Playlist Deleted", "The playlist was deleted from the Subsonic Server") 
        else
            #NSLog "There was an error deleting the playlist from the server #{xml}"
            g.notify("notification", "Error Deleting Playlist", "The playlist was not deleted from the Subsonic Server") 
        end
        parent.playlists_table_view.deselectAll(nil)
    end
    
    
end
