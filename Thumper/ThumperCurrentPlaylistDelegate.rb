#
#  ThumperCurrentPlaylistDelegate.rb
#  Thumper
#
#  Created by Daniel Westendorf on 4/4/11.
#  Copyright 2011 Daniel Westendorf. All rights reserved.
#


class ThumperCurrentPlaylistDelegate

    attr_accessor :parent, :save_window, :playlist_name
    
    def numberOfRowsInTableView(tableView)
        parent.current_playlist.count 
    end
    
    def tableView(tableView, objectValueForTableColumn:column, row:row)
        NSLog "Asked for Current Playlist Row:#{row}, Column:#{column.identifier}"
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
        parent.current_playlist_table_view.registerForDraggedTypes(NSArray.arrayWithObjects("Song", nil))
    end
    
    def tableView(aView, validateDrop:info, proposedRow:row, proposedDropOperation:op)
        if op == NSTableViewDropAbove; return NSDragOperationEvery; else return NSDragOperationNone; end
    end
    
    def tableView(aView, writeRowsWithIndexes:rowIndexes, toPasteboard:pboard)
        song = parent.current_playlist[rowIndexes.firstIndex].to_yaml
        pboard.setString(song, forType:"Song")
        return true
    end
    
    def tableView(aView, acceptDrop:info, row:row, dropOperation:op)
        pboard = info.draggingPasteboard
        song = YAML.load(pboard.stringForType("Song"))
        row -= 1 if row > parent.current_playlist.find_index(song)
        
        NSLog "Rearrange #{song[:id]}, new row #{row}"
        if parent.current_playlist.include?(song)
            if song[:id] == parent.current_playlist[parent.playing_song][:id]
                parent.playing_song = row
            elsif parent.playing_song >= row
                parent.playing_song += 1
            end

            parent.current_playlist.insert(row, parent.current_playlist.delete(song))
        else
           parent.current_playlist.insert(row, song) 
        end
        parent.reload_current_playlist
        Dispatch::Queue.new('com.Thumper.db').sync do
            DB[:playlist_songs].filter(:playlist_id => "666current666").delete
            DB.transaction do
                parent.current_playlist.each do |psong|
                    DB[:playlist_songs].insert(:name => "Current", :playlist_id => "666current666", :song_id => psong[:id])
                end
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
        @parent.reload_current_playlist
        @parent.set_playing_info
        @parent.set_playing_cover_art
        @parent.playing_song_object_progress.stopAnimation(nil)
    end
    
    def remove_selected_from_playlist(sender)
        selected = parent.current_playlist_table_view.selectedRow
        if selected > -1
            song_id = @parent.current_playlist[selected][:id]
            DB[:playlist_songs].filter(:song_id => song_id).delete
            @parent.current_playlist.delete_at(selected)
            @parent.reload_current_playlist
            @parent.play_song if selected == @parent.playing_song && @parent.current_playlist.length > 0
        end
    end
    
    def save_playlist(sender)
        NSLog "Saving Playlist"
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
    
    def save_playlist_response(xml)
        NSLog "Playlist saved"
    end
    
end