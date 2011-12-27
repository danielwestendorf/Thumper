#
#  ThumperCurrentPlaylistDelegate.rb
#  Thumper
#
#  Created by Daniel Westendorf on 4/4/11.
#  Copyright 2011 Daniel Westendorf. All rights reserved.
#


class ThumperCurrentPlaylistDelegate

    attr_accessor :parent, :save_window, :playlist_name, :share_enabled, :rate_enabled
    
    def initialize
        @share_enabled = true 
        @rate_enabled = true
    end
    
    def represented_objects
        parent.current_playlist 
    end
    
    def numberOfRowsInTableView(tableView)
        parent.current_playlist.count 
    end
    
    def tableView(tableView, objectValueForTableColumn:column, row:row)
        #NSLog "Asked for Current Playlist Row:#{row}, Column:#{column.identifier}"
        if row < parent.current_playlist.length
            if column.identifier == "indicator"
                return NSImage.imageNamed("Playing") if row == parent.playing_song
            else
                return parent.current_playlist[row].valueForKey(column.identifier.to_sym)
            end
        end
        nil
    end
    
    def awakeFromNib
        parent.current_playlist_table_view.doubleAction = 'double_click:'
        parent.current_playlist_table_view.target = self
        parent.current_playlist_table_view.registerForDraggedTypes(NSArray.arrayWithObjects("Songs", nil))
    end
    
    def tableView(aView, validateDrop:info, proposedRow:row, proposedDropOperation:op)
        if op == NSTableViewDropAbove; return NSDragOperationEvery; else return NSDragOperationNone; end
    end
    
    def tableView(aView, writeRowsWithIndexes:rowIndexes, toPasteboard:pboard)
        songs_array = []
        rowIndexes.each do |row|
           songs_array << parent.current_playlist[row]
        end
        pboard.setString(songs_array.to_yaml, forType:"Songs")
        return true
    end
    
    def tableView(aView, acceptDrop:info, row:row, dropOperation:op)
        pboard = info.draggingPasteboard
        songs = YAML.load(pboard.stringForType("Songs"))
        playing_song = parent.current_playlist[parent.playing_song] if parent.playing_song
        songs.reverse.each do |song|
            current_position = parent.current_playlist.find_index(song)
        
            row = 0 if row < 0

            #NSLog "Current: #{current_position}, New: #{row} #{song}"
            
            if current_position.nil?
                parent.current_playlist.insert(row, song)
            else
                row > current_position ? row -= 1 : row
                parent.current_playlist.insert(row, parent.current_playlist.delete(song))
            end
            parent.current_playlist.delete(nil)
    
            parent.playing_song = parent.current_playlist.find_index(playing_song) if parent.playing_song
        end
        
        parent.current_playlist_table_view.deselectAll(nil)
        parent.reload_current_playlist
        @parent.db_queue.async do
            DB[:playlist_songs].filter(:playlist_id => "666current666").delete
            parent.current_playlist.each do |psong|
                DB[:playlist_songs].insert(:name => "Current", :playlist_id => "666current666", :song_id => psong[:id])
            end
        end
        return true
    end

    def double_click(sender)
        @parent.playing_song = parent.current_playlist_table_view.selectedRow
        @parent.play_song
    end
    
    def clear_playlist(sender)
        @parent.current_playlist = []
        DB[:playlist_songs].filter(:playlist_id => '666current666').delete
        @parent.playing_song_object.stop
        @parent.playing_song = nil
        @parent.playing_song_object = QTMovie.alloc
        @parent.update_progress_bar(nil)
        @parent.reload_current_playlist
        @parent.set_playing_info
        @parent.set_playing_cover_art
        @parent.playing_song_object_progress.stopAnimation(nil)
        @parent.cancel_timer
        @parent.hide_notification_view(nil)
        @parent.change_notification_text(nil)
    end
    
    def remove_selected_from_playlist(sender)
        remove_from_playlist
    end
    
    def pressed_delete
       remove_from_playlist 
    end
    
    def remove_from_playlist
        selected = parent.current_playlist_table_view.selectedRowIndexes
        selected.each do |index|
            if index > -1
                if index == parent.playing_song
                    @parent.cancel_timer
                    @parent.playing_song_object.stop
                    @parent.playing_song_object = QTMovie.alloc
                    @parent.playing_song = nil
                    @parent.set_playing_info
                    parent.set_playing_cover_art
                end
                song_id = @parent.current_playlist[index][:id]
                DB[:playlist_songs].filter(:song_id => song_id).delete
            end
        end
        selected.each do |index|
           if index > -1
               @parent.playing_song -= 1 if index && @parent.playing_song && index < @parent.playing_song
               @parent.current_playlist.delete_at(index)
               @parent.reload_current_playlist
               @parent.play_song if selected == @parent.playing_song && @parent.current_playlist.length > 0
           end
        end
        @parent.current_playlist_table_view.deselectAll(nil)
        @parent.cancel_timer if @parent.current_playlist.length < 1
    end
    
    def save_playlist(sender)
        #NSLog "Saving Playlist"
        if parent.current_playlist.length > 0
            names = parent.playlists.collect {|p| p[:name]}
            playlist_name.addItemsWithObjectValues(names)
            NSApp.beginSheet(save_window,
                         modalForWindow:parent.main_window,
                         modalDelegate:self,
                         didEndSelector:nil,
                         contextInfo:nil) 
        end
    end
    
    def submit_playlist_name(sender)
        name = playlist_name.stringValue
        song_ids = parent.current_playlist.collect {|song| song[:id]}
        parent.subsonic.create_playlist(name, song_ids, self, :save_playlist_response)
        NSApp.endSheet(save_window)
        save_window.orderOut(sender)
        DB[:playlist_songs].filter(:name => name).delete
    end
    
    def close_save_window(sender)
        NSApp.endSheet(save_window)
        save_window.orderOut(sender)
    end
    
    def save_playlist_response(xml, options)
        #g = Growl.new("Thumper", ["notification"])
        if xml.class == NSXMLDocument && xml.nodesForXPath('subsonic-response', error:nil).first.attributeForName(:status).stringValue == "ok"
            #NSLog "Playlist saved successfully"
            #@parent.notification_queue.add_notification({:title => "Playlist Saved", :message => "The playlist was saved to the Subsonic Server", :image => NSImage.imageNamed("LogoWhite")})
            @parent.change_notification_text("The playlist was saved to the Subsonic Server")
            #g.notify("notification", "Playlist Saved", "The playlist was saved to the Subsonic Server") 
            @parent.get_playlists
        else
            #NSLog "Error saving playlist #{xml}"
            #g.notify("notification", "Error Saving Playlist", "The playlist was not saved to the Subsonic Server")
            @parent.change_notification_text("Error. The playlist was not saved to the Subsonic Server")
            #@parent.notification_queue.add_notification({:title => "Error Saving Playist", :message => "There was an error saving the playlist to the server", :image => NSImage.imageNamed("LogoWhite")})
        end
    end
    
    def select_all
        range = NSMakeRange(0, parent.current_playlist.length)
        indexes = NSIndexSet.alloc.initWithIndexesInRange(range)
        parent.current_playlist_table_view.selectRowIndexes(indexes, byExtendingSelection:true)
    end
    
    def sort_by_year(sender)
        sort_by_key(:year, :to_i) 
    end
    
    def sort_by_artist(sender)
        sort_by_key(:artist, :to_s) 
    end
    
    def sort_by_album(sender)
        sort_by_key(:album, :to_s) 
    end
    
    def sort_by_length(sender)
        sort_by_key(:duration, :to_s) 
    end
    
    def sorty_by_track(sender)
        sort_by_key(:track, :to_i) 
    end
    
    def sort_by_key(key, type)
        playing_song_item = parent.current_playlist[parent.playing_song]
        parent.current_playlist.sort_by! {|song| song[key].method(type).call() }
        parent.playing_song = parent.current_playlist.find_index(playing_song_item)
        parent.reload_current_playlist 
    end
    
end