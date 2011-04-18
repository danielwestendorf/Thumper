class ThumperSearchDelegate
    attr_accessor :parent, :search_query, :search_table_view, :search
    
    def initialize
        @search = []
    end
    
    def awakeFromNib
        search_table_view.doubleAction = 'double_click:'
        search_table_view.target = self
    end
    
    def double_click(sender)
        row = search_table_view.selectedRow
        parent.add_to_current_playlist(search[row])
    end
    
    def numberOfRowsInTableView(tableView)
        @search.count
    end
    
    def tableView(tableView, objectValueForTableColumn:column, row:row)
        NSLog "Asked for Song Row:#{row}, Column:#{column.identifier}"
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
    
    def textInputOnEnterPressed(sender)
        NSLog "searching for by #{search_query.stringValue}"
        query = search_query.stringValue.downcase.strip
        unless query.empty?
            parent.subsonic.search(query, self, :search_response)
        end
    end
    
    def add_selected_to_playlist(sender)
        row = search_table_view.selectedRow
        row = 0 if row.nil?
        parent.add_to_current_playlist(parent.search[row])
    end
    
    def search_response(xml)
        if xml.class == NSXMLDocument
            songs = xml.nodesForXPath("subsonic-response", error:nil).first.nodesForXPath('searchResult', error:nil).first.nodesForXPath('match', error:nil)
            total_results = xml.nodesForXPath("subsonic-response", error:nil).first.nodesForXPath('searchResult', error:nil).first.nodesForXPath('totalHits', error:nil)
            offset = xml.nodesForXPath("subsonic-response", error:nil).first.nodesForXPath('searchResult', error:nil).first.nodesForXPath('offset', error:nil)
            attributeNames = ["id", "title", "artist", "coverArt", "parent", "isDir", "duration", "bitRate", "track", "year", "genre", "size", "suffix",
            "album", "path", "size"]
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
                NSLog "Duration: #{song[:duration]}"
                @search << song if song[:isDir] == "false"
            end
            search_table_view.reloadData
        end

    end
end