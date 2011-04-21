require 'uri'

class ThumperSearchDelegate
    attr_accessor :parent, :search_query, :search_table_view, :search, :search_progress, :search_count_label
    
    def initialize
        @search = []
    end
    
    def awakeFromNib
        search_table_view.doubleAction = 'double_click:'
        search_table_view.target = self
    end
    
    def double_click(sender)
        row = @search_table_view.selectedRow
        row = 0 if row.nil?
        song = @search[row]
        parent.get_cover_art(song[:coverArt]) unless song[:coverArt].nil? || File.exists?(song[:cover_art])
        parent.add_to_current_playlist(song)
    end
    
    def numberOfRowsInTableView(tableView)
        @search.count
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
        NSLog "searching for by #{search_query.stringValue}"
        query = URI.escape(search_query.stringValue.downcase.strip)
        @search_progress.stopAnimation(nil)
        unless query.length < 3
            @search = []
            reload_search
            @search_progress.startAnimation(nil)
            parent.subsonic.search(query, self, :search_response)
        end
    end
    
    def add_selected_to_playlist(sender)
        row = search_table_view.selectedRow
        row = 0 if row.nil?
        parent.add_to_current_playlist(@search[row])
    end
    
    def reload_search
        @search.count != 1 ? word = " Songs" : word = " Song"
        @search_count_label.stringValue = @search.count.to_s + word
        search_table_view.reloadData
    end
    
    def search_response(xml)
        NSLog "got a response"
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
            reload_search
            @search_progress.stopAnimation(nil)
        else
            NSLog "#{xml}"
        end
    end
    
end