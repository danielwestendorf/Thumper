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
end