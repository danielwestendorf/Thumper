require 'uri'

class ThumperSearchDelegate
    attr_accessor :parent, :search_query, :search_table_view, :search_progress, :search_count_label, :share_enabled, :rate_enabled
    
    def initialize
        @share_enabled = true
        @rate_enabled = true
    end
    
    def represented_objects
        parent.search_results 
    end
    
    def initialize
        @search = []
    end
    
    def awakeFromNib
        search_table_view.doubleAction = 'double_click:'
        search_table_view.target = self
    end
    
    def double_click(sender)
        row = @search_table_view.selectedRow
        @parent.add_to_current_playlist(@parent.search_results[row])
    end
    
    def numberOfRowsInTableView(tableView)
        @parent.search_results.count
    end
    
    def tableView(tableView, objectValueForTableColumn:column, row:row)
        #NSLog "Asked for Song Row:#{row}, Column:#{column.identifier}"
        if row < @search.length
            return @search[row].valueForKey(column.identifier.to_sym)
        end
        nil
    end
    
    def textInputOnEnterPressed(sender)
        reload_search
        #NSLog "searching for by #{search_query.stringValue}"
        query = URI.escape(search_query.stringValue.downcase.strip)
        @search_progress.stopAnimation(nil)
        unless query.length < 3
            @search = []
            reload_search
            @search_progress.startAnimation(nil)
            parent.subsonic.search(query, self, :search_response)
        end
    end
    
    def add_selected(sender)
        rows = search_table_view.selectedRowIndexes
        row_collection = []
        if rows.count > 0
            rows.each do |row|
                row_collection << row
            end
            row_collection.reverse.each {|r| @parent.add_to_current_playlist(@parent.search_results[r], false)  }
        else
            @search.each do |song|
                parent.add_to_current_playlist(song, false)
            end
        end
        parent.reload_current_playlist
        parent.play_song if parent.current_playlist.length == 1
    end
    
    def reload_search
        @search.count != 1 ? word = " Songs" : word = " Song"
        @search_count_label.stringValue = @search.count.to_s + word
        search_table_view.reloadData
    end
    
    def tableView(aView, writeRowsWithIndexes:rowIndexes, toPasteboard:pboard)
        songs_array = []
        rowIndexes.each do |row|
            songs_array << @search[row]
        end
        pboard.setString(songs_array.reverse.to_yaml, forType:"Songs")
        return true
    end
    
    def select_all
        range = NSMakeRange(0, parent.search_results.length)
        indexes = NSIndexSet.alloc.initWithIndexesInRange(range)
        @search_table_view.selectRowIndexes(indexes, byExtendingSelection:true)
    end
    
    def pressed_delete
        return nil
    end
    
    def search_response(xml, options)
        #NSLog "got a response"
        if xml.class == NSXMLDocument
            songs = xml.nodesForXPath("subsonic-response", error:nil).first.nodesForXPath('searchResult', error:nil).first.nodesForXPath('match', error:nil)
            attributeNames = ["id", "title", "artist", "coverArt", "parent", "isDir", "duration", "bitRate", "track", "year", "genre", "size", "suffix",
            "album", "path", "size"]
            if songs.length > 0
                @search = []
                songs.each do |xml_song|
                    song = {}
                    attributeNames.each do |name|
                        song[name.to_sym] = xml_song.attributeForName(name).stringValue unless xml_song.attributeForName(name).nil? 
                    end
                    song[:cover_art] = Dir.home + "/Library/Thumper/CoverArt/#{song[:coverArt]}.jpg"
                    song[:album_id] = song[:parent]
                    song[:bitrate] = song[:bitRate]
                    song[:duration] = @parent.format_time(song[:duration].to_i)
                    song[:cache_path] = Dir.home + '/Music/Thumper/' + song[:path]
                    @search << song if song[:isDir] == "false"
                end 
            end
            @parent.search_results = @search
            reload_search
            @search_progress.stopAnimation(nil)
            
            @parent.db_queue.sync do
                @search.each do |song|
                    unless DB[:songs].filter(:id => song[:id]).all.first 
                        DB[:songs].insert(:id => song[:id], :title => song[:title], :artist => song[:artist], :duration => song[:duration], 
                                      :bitrate => song[:bitrate], :track => song[:track], :year => song[:year], :genre => song[:genre],
                                      :size => song[:size], :suffix => song[:suffix], :album => song[:album], :album_id => song[:album_id],
                                      :cover_art => song[:cover_art], :path => song[:path], :cache_path => song[:cache_path])
                    end
                end
            end
        else
            NSLog "Error with search!"
        end
    end
    
end