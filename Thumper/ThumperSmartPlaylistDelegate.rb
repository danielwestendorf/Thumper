class ThumperSmartPlaylistDelegate
    attr_accessor :parent

    def numberOfRowsInTableView(tableView)
        parent.smart_playlists.count 
    end
    
    def tableView(tableView, objectValueForTableColumn:column, row:row)
        #NSLog "Asked for QP Row:#{row}, Column:#{column.identifier}"
        if row < parent.smart_playlists.length
            return parent.smart_playlists[row][:name] 
        end
        nil
    end
    
    def reload_sp(sender)
        row = parent.smart_playlists_table_view.selectedRow
        raw_hash = parent.smart_playlists[row]
        hash = {}
        [:genre, :size, :toYear, :fromYear].each do |k|
            hash[k] = raw_hash[k] unless raw_hash[k].empty?
        end
        
        parent.get_smart_playlist(hash) 
    end
    
    def tableViewSelectionDidChange(notification)
        row = parent.smart_playlists_table_view.selectedRow
        if row > -1
            parent.playlists_table_view.deselectAll(nil)
            parent.playlist_songs_reload_button.setTarget(self)
            parent.playlist_songs_reload_button.setAction("reload_sp:")
            parent.playlist_songs = []
            parent.playlists_table_view.deselectAll(nil)
            parent.reload_playlist_songs
            raw_hash = parent.smart_playlists[row]
            hash = {}
            [:genre, :size, :toYear, :fromYear].each do |k|
                hash[k] = raw_hash[k] unless raw_hash[k].empty?
            end
            
            parent.get_smart_playlist(hash) 
            #NSLog "Selected SP #{parent.smart_playlists_table_view.selectedRow}, #{parent.smart_playlists[parent.quick_playlists_table_view.selectedRow][:name]}"
        end
    end
    
    def add_smart_playlist(sender)
        genres = DB[:songs].group(:genre).all.collect {|p| p[:genre] }
        parent.sp_genre.addItemsWithObjectValues(genres)
        sp_modal = SimpleModal.new(@parent.main_window, @parent.new_sp_window)
        sp_modal.show
        sp_modal.add_outlet(parent.new_sp_cancel) do
            nil
        end
        
        sp_modal.add_outlet(parent.new_sp_save, true) do
            playlist = {:name => parent.sp_name.stringValue, :size => parent.sp_size.stringValue, :genre => parent.sp_genre.stringValue, :fromYear => parent.sp_fromYear.stringValue, :toYear => parent.sp_toYear.stringValue}
            parent.smart_playlists << playlist
            @parent.db_queue.sync do
                DB[:smart_playlists].insert(playlist)
                parent.smart_playlists_table_view.reloadData
                g = Growl.new("Thumper", ["notification"])
                g.notify("notification", "Smart Playlist Saved", "The Smart Playlist #{playlist[:name]} was created")
            end
        end
    end
    
    def delete_smart_playlist(sender)
        row = parent.smart_playlists_table_view.selectedRow
        playlist_hash = parent.smart_playlists[row]
        @parent.db_queue.sync do
            DB[:smart_playlists].filter(:id => playlist_hash[:id]).delete
            g = Growl.new("Thumper", ["notification"])
            g.notify("notification", "Smart Playlist Deleted", "The Smart Playlist #{playlist_hash[:name]} was deleted")
        end
        parent.smart_playlists.delete_at(row)
        parent.smart_playlists_table_view.reloadData
    end
end