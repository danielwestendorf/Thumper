class ThumperSearchDelegate
    attr_accessor :parent, :search_query, :search_table_view, :search
    
    def awakeFromNib
        search_table_view.doubleAction = 'double_click:'
        search_table_view.target = self
    end
    
    def double_click(sender)
        row = search_table_view.selectedRow
        parent.add_to_current_playlist(search[row])
        parent.play_song if parent.current_playlist.length == 1
    end
    
    def numberOfRowsInTableView(tableView)
        search.count 
    end
    
    def tableView(tableView, objectValueForTableColumn:column, row:row)
        #NSLog "Asked for Song Row:#{row}, Column:#{column.identifier}"
        if row < search.length
            return search[row].valueForKey(column.identifier.to_sym)
        end
        nil
    end
    
    def add_all_songs_to_current(sender)
        Dispatch::Queue.new('com.Thumper.playlist_thread').sync do
            search.each do |song|
                parent.add_to_current_playlist(song)
                parent.play_song if parent.current_playlist.length == 1
            end
        end
    end
    
    def add_selected_to_playlist(sender)
        row = search_table_view.selectedRow
        row = 0 if row.nil?
        parent.add_to_current_playlist(parent.search[row])
    end
end