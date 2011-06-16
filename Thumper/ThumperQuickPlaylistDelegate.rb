class ThumperQuickPlaylistDelegate
    attr_accessor :parent
    
    def numberOfRowsInTableView(tableView)
        parent.quick_playlists.count 
    end
    
    def tableView(tableView, objectValueForTableColumn:column, row:row)
        #NSLog "Asked for QP Row:#{row}, Column:#{column.identifier}"
        if row < parent.quick_playlists.length
            return parent.quick_playlists[row][0] 
        end
        nil
    end
    
    def tableViewSelectionDidChange(notification)
        if parent.quick_playlists_table_view.selectedRow > -1
            parent.artist_indexes_table_view.deselectAll(nil)
            parent.qp_offset = 0
            parent.album_reload_button.setAction("update_qp_albums:")
            parent.albums = []
            parent.songs = []
            parent.albums_table_view.enabled = false
            parent.songs_table_view.enabled = false
            parent.reload_albums
            parent.reload_songs
            parent.get_quick_playlist({:type => parent.quick_playlists[parent.quick_playlists_table_view.selectedRow][1]}) 
            #NSLog "Selected QP #{parent.quick_playlists_table_view.selectedRow}, #{parent.quick_playlists[parent.quick_playlists_table_view.selectedRow][1]}"
        end
    end

end