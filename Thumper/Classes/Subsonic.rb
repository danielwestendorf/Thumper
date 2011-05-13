require 'base64'

class Subsonic
    attr_reader :connectivity
    
	def initialize(parent, base_url, username, password)
        @parent = parent
		@base_url = base_url
		@auth_token = Base64.encode64("#{username}:#{password}").strip
		@extra_params = "&f=xml&v=1.4.0&c=Thumper"
	end
	
	#response methods
	def ping_response(xml)
		if xml.class == NSXMLDocument && xml.nodesForXPath('subsonic-response', error:nil).first.attributeForName(:status).stringValue == "ok"
            @parent.status_label.stringValue = "Online" 
            NSLog "Online"
            @connectivity = true
            @parent.get_artist_indexes
            @parent.get_playlists
        elsif xml.class == NSXMLDocument
            @parent.status_label.stringValue = "Offline -- #{xml.nodesForXPath('subsonic-response', error:nil).first.nodesForXPath('error', error:nil).first.attributeForName('message').stringValue}"
            connectivity = false
            NSLog "Offline"
        elsif xml.class == Fixnum
            case xml
                when 401 then @parent.status_label.stringValue = "Offline -- Wrong username or password"
                when 403 then @parent.status_label.stringValue = "Offline -- Access denied"
                when 404 then @parent.status_label.stringValue = "Offline -- Resource not found"
                when 500..600 then @parent.status_label.stringValue = "Offline -- Server error"
            end
		end
		xml = nil
	end
	
	def albums_response(xml)
        @albums = []
        if xml.class == NSXMLDocument && xml.nodesForXPath('subsonic-response', error:nil).first.attributeForName(:status).stringValue == "ok"
            albums = xml.nodesForXPath("subsonic-response", error:nil).first.nodesForXPath('directory', error:nil).first.nodesForXPath('child', error:nil)
            albums.each do |xml_album|
                attributeNames = ["id", "title", "artist", "coverArt", "parent", "isDir"]
                album = {}
                attributeNames.each do |name|
                    album[name.to_sym] = xml_album.attributeForName(name).stringValue unless xml_album.attributeForName(name).nil? 
                end
                album[:cover_art] = Dir.home + "/Library/Thumper/CoverArt/#{album[:coverArt]}.jpg"
                album[:artist_id] = album[:parent]
                @albums << album if album[:isDir] == "true"
                @parent.get_cover_art(album[:coverArt]) unless album[:coverArt].nil? || File.exists?(album[:cover_art]) 
            end
        else
            NSLog "Invalid response from server"
        end
        xml = nil
        NSLog "Update of artist albums complete. #{@albums.length} albums"
        if @parent.artists[@parent.artist_indexes_table_view.selectedRow][:id] == @albums.first[:artist_id]
            @parent.albums = @albums
            @parent.reload_albums
        end
        NSLog "Persisting albums to the DB"
        if DB[:albums].filter(:artist_id => @albums.first[:artist_id]).all.count < 1
            DB.transaction do
                @albums.each {|a| DB[:albums].insert(:title => a[:title], :id => a[:id], :cover_art => a[:cover_art], :artist_id => a[:artist_id]) } 
            end
        else
            Dispatch::Queue.new('com.qweef.db').async do
                @albums.each do |a|
                    return if DB[:albums].filter(:id => a[:id]).all.first 
                    DB[:albums].insert(:title => a[:title], :id => a[:id], :cover_art => a[:cover_art], :artist_id => a[:artist_id])
                    NSLog "Added Album: #{a[:title]}"
                end
            end
        end
        NSLog "All Albums presisted to the DB"
        @parent.albums_progress.stopAnimation(nil)
        @parent.get_album_songs(@albums.first[:id]) if @albums.length == 1
	end
	
	def songs_response(xml)
        @songs = []
        if xml.class == NSXMLDocument && xml.nodesForXPath('subsonic-response', error:nil).first.attributeForName(:status).stringValue == "ok"
            songs = xml.nodesForXPath("subsonic-response", error:nil).first.nodesForXPath('directory', error:nil).first.nodesForXPath('child', error:nil)
            attributeNames = ["id", "title", "artist", "coverArt", "parent", "isDir", "duration", "bitRate", "track", "year", "genre", "size", "suffix",
                            "album", "path", "size"]
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
                @songs << song if song[:isDir] == "false"
            end
        else
            NSLog "Invalid response from server"
        end
        NSLog "Update of ablum songs complete. #{@songs.length} songs"
        xml = nil
        if @songs.length > 0 && @parent.albums[@parent.albums_table_view.selectedRow][:id] == @songs.first[:album_id]
            @parent.songs = @songs
            @parent.reload_songs
            @parent.songs_table_view.enabled = true
        end
        NSLog "Persisting songs to the DB"
        if @songs.length > 0 && DB[:songs].filter(:album_id => @songs.first[:album_id]).all.count < 1
            DB.transaction do
                @songs.each {|s| DB[:songs].insert(:id => s[:id], :title => s[:title], :artist => s[:artist], :duration => s[:duration], 
                                                   :bitrate => s[:bitrate], :track => s[:track], :year => s[:year], :genre => s[:genre],
                                                   :size => s[:size], :suffix => s[:suffix], :album => s[:album], :album_id => s[:album_id],
                                                   :cover_art => s[:cover_art], :path => s[:path], :cache_path => s[:cache_path]) } 
            end
        else
            @parent.db_queue.async do
                @songs.each do |s|
                    return if DB[:songs].filter(:id => s[:id]).all.first 
                    DB[:songs].insert(:id => s[:id], :title => s[:title], :artist => s[:artist], :duration => s[:duration], 
                                       :bitrate => s[:bitrate], :track => s[:track], :year => s[:year], :genre => s[:genre],
                                       :size => s[:size], :suffix => s[:suffix], :album => s[:album], :album_id => s[:album_id],
                                       :cover_art => s[:cover_art], :path => s[:path], :cache_path => s[:cache_path])
                    NSLog "Added songs: #{song[:title]}"
                end
            end
        end
        @parent.songs_progress.stopAnimation(nil)
        NSLog "All songs presisted to the DB"
	end
	
	def artists_response(xml)
        @artists = []
		if xml.class == NSXMLDocument && xml.nodesForXPath('subsonic-response', error:nil).first.attributeForName(:status).stringValue == "ok"
            indexes = xml.nodesForXPath("subsonic-response", error:nil).first.nodesForXPath('indexes', error:nil).first.nodesForXPath('index', error:nil)
            indexes.each do |index|
                artists = index.nodesForXPath('artist', error:nil)
                artists.each {|a| @artists << {:name => a.attributeForName("name").stringValue, :id => a.attributeForName("id").stringValue} }
            end
            else
            NSLog "Invalid response from server"
		end
		xml = nil
        @parent.artists = @artists 
        @parent.all_artists = @artists
        @parent.artists.count != 1 ? word = " Artists" : word = " Artist"
        @parent.artist_count_label.stringValue = @artists.count.to_s + word
        @parent.artist_indexes_table_view.reloadData
        NSLog "Persisting Aritsts to the DB"
        if DB[:artists].all.count < 1
            DB.transaction do
                @artists.each {|a| DB[:artists].insert(:name => a[:name], :id => a[:id]) } 
            end
        else
            @parent.db_queue.async do
                @artists.each do |a|
                    return if DB[:artists].filter(:id => a[:id]).all.first 
                    DB[:artists].insert(:id => a[:id], :name => a[:name])
                    NSLog "Added Artist: #{a[:name]}"
                end
            end
        end
        @parent.artists_progress.stopAnimation(nil)
        NSLog "All Artists presisted to the DB #{@parent.artists.length}"
	end

    def playlists_response(xml)
        @playlists = []
        if xml.class == NSXMLDocument && xml.nodesForXPath('subsonic-response', error:nil).first.attributeForName(:status).stringValue == "ok"
            playlists = xml.nodesForXPath("subsonic-response", error:nil).first.nodesForXPath('playlists', error:nil).first.nodesForXPath('playlist', error:nil)
            playlists.each do |playlist|
                @playlists << {:name => playlist.attributeForName("name").stringValue, :id => playlist.attributeForName("id").stringValue}
            end
        end
        NSLog "Got playlists from server"
        @parent.playlists = @playlists
        @parent.reload_playlists
        @parent.playlists_progress.stopAnimation(nil)
    end
    
    def playlist_response(xml)
        @playlist_songs = []
        if xml.class == NSXMLDocument && xml.nodesForXPath('subsonic-response', error:nil).first.attributeForName(:status).stringValue == "ok"
            playlist_id = xml.nodesForXPath("subsonic-response", error:nil).first.nodesForXPath('playlist', error:nil).first.attributeForName("id").stringValue
            playlist_name = xml.nodesForXPath("subsonic-response", error:nil).first.nodesForXPath('playlist', error:nil).first.attributeForName("name").stringValue
            playlist_songs = xml.nodesForXPath("subsonic-response", error:nil).first.nodesForXPath('playlist', error:nil).first.nodesForXPath('entry', error:nil)
            attributeNames = ["id", "title", "artist", "coverArt", "parent", "isDir", "duration", "bitRate", "track", "year", "genre", "size", "suffix",
            "album", "path", "size"]
            playlist_songs.each do |xml_song|
                song = {}
                attributeNames.each do |name|
                    song[name.to_sym] = xml_song.attributeForName(name).stringValue unless xml_song.attributeForName(name).nil? 
                end
                song[:cover_art] = Dir.home + "/Library/Thumper/CoverArt/#{song[:coverArt]}.jpg"
                song[:album_id] = song[:parent]
                song[:bitrate] = song[:bitRate]
                song[:duration] = @parent.format_time(song[:duration].to_i)
                song[:cache_path] = Dir.home + '/Music/Thumper/' + song[:path]
                @playlist_songs << song if song[:isDir] == "false"
            end 
        end
        @parent.playlist_songs = @playlist_songs if @parent.playlists[@parent.playlists_table_view.selectedRow][:id] == playlist_id
        @parent.db_queue.async do
            DB[:playlist_songs].filter(:playlist_id => playlist_id).delete
            @playlist_songs.each do |s|
                if DB[:songs].filter(:id => s[:id]).all.first.nil?
                    DB[:songs].insert(:id => s[:id], :title => s[:title], :artist => s[:artist], :duration => s[:duration], 
                                  :bitrate => s[:bitrate], :track => s[:track], :year => s[:year], :genre => s[:genre],
                                  :size => s[:size], :suffix => s[:suffix], :album => s[:album], :album_id => s[:album_id],
                                  :cover_art => s[:cover_art], :path => s[:path], :cache_path => s[:cache_path])
                end
                DB[:playlist_songs].insert(:playlist_id => playlist_id, :name => playlist_name, :song_id => s[:id])
            end
        end
        @parent.reload_playlist_songs
        @parent.playlist_songs_progress.stopAnimation(nil)
    end
    
    def image_response(data, path, id)
        response = data.writeToFile(path, atomically:true)
        @parent.albums_table_view.reloadData
        @parent.set_playing_cover_art
    end
    
    def download_media_response(data, path, id)
        path_step = "/"
        split_path = path.split('/')
        split_path.delete_at(0)
        split_path.delete_at(split_path.length - 1)
        split_path.each do |dir|
            path_step << dir
            if !File.exists?(path_step)
                Dir.mkdir(path_step)
            end
            path_step << '/'
        end
        response = data.writeToFile(path, atomically:true)
        NSLog "Saved downloaded file to #{path}"
    end
	
    def scrobble_response(xml)
        NSLog "Successfully scrobbled song" if xml.class == NSXMLDocument 
    end
	
	#Actual data request methods
	def ping(delegate, method)
        request = build_request("/rest/ping.view", {})
        NSURLConnection.connectionWithRequest(request, delegate:XMLResponse.new(delegate, method))
	end
    
    def check_connectivity(timer)
        ping(self, :ping_response)
    end
	
	def getLicense(delegate, method)
        request = build_request('/rest/getLicense.view', {})
        NSURLConnection.connectionWithRequest(request, delegate:XMLResponse.new(delegate, method))
	end
	
	def artists(delegate, method)
        request = build_request('/rest/getIndexes.view', {})
        NSURLConnection.connectionWithRequest(request, delegate:XMLResponse.new(delegate, method))
	end
	
	def albums(id, delegate, method)
        NSLog "Getting album #{id}"
        request = build_request('/rest/getMusicDirectory', {:id => id})
        NSURLConnection.connectionWithRequest(request, delegate:XMLResponse.new(delegate, method))
	end
	
	def songs(id, delegate, method)
        request = build_request('/rest/getMusicDirectory', {:id => id})
        NSURLConnection.connectionWithRequest(request, delegate:XMLResponse.new(delegate, method))
	end
    
    def cover_art(id, delegate, method)
        request = build_request('/rest/getCoverArt.view', {:id => id})
        path = Dir.home + "/Library/Thumper/CoverArt/#{id}.jpg"
        NSURLConnection.connectionWithRequest(request, delegate:DownloadResponse.new(path, nil, delegate, method))
    end
    
    def playlists(delegate, method)
        request = build_request('/rest/getPlaylists.view', {})
        NSURLConnection.connectionWithRequest(request, delegate:XMLResponse.new(delegate, method))
    end
    
    def playlist(id, delegate, method)
        request = build_request('/rest/getPlaylist.view', {:id => id})
        NSURLConnection.connectionWithRequest(request, delegate:XMLResponse.new(delegate, method))
    end
    
    def delete_playlist(id, delegate, method)
        request = build_request('/rest/deletePlaylist.view', {:id => id})
        NSURLConnection.connectionWithRequest(request, delegate:XMLResponse.new(delegate, method))
    end
    
    def search(query, delegate, method)
        request = build_request('/rest/search.view', {:any => query, :count => 100})
        NSURLConnection.connectionWithRequest(request, delegate:XMLResponse.new(delegate, method))
    end
    
    def create_playlist(name, song_ids, delegate, method)
        request = build_request('/rest/createPlaylist.view', {})
        request.HTTPMethod = "POST"
        body = "name=#{name}"
        song_ids.each {|id| body << "&songId=#{id}" }
        request.HTTPBody = body.dataUsingEncoding(NSUTF8StringEncoding)
        NSURLConnection.connectionWithRequest(request, delegate:XMLResponse.new(delegate, method))
    end
    
    def download_media(path, id, delegate, method)
        NSLog "Attempting to download #{id}"
        request = build_request('/rest/download.view', {:id => id})
        NSURLConnection.connectionWithRequest(request, delegate:DownloadResponse.new(path, id, delegate, method))
    end
    
    def scrobble(id, delegate, method)
        NSLog "Attempting to scrobble now playing"
        scrobble_request = build_request('/rest/scrobble.view', {:id => id})
        NSURLConnection.connectionWithRequest(scrobble_request, delegate:XMLResponse.new(delegate, method))
        now_playing_request = build_request('/rest/stream.view', {:id => id})
        @conn = NSURLConnection.connectionWithRequest(now_playing_request, delegate:self)
    end
    
    def connection(connection, didReceiveResponse:response)
        if response.statusCode == 200..300
            @conn.cancel
            NSLog "Canceled KilledResposne"
            else
            NSLog "There was an error with the request: #{response.statusCode}"
        end
    end
	
	private
	
	def build_request(resource, options)
        options_string = options.collect do |key, value| 
            if value.class != Array
                "#{key}=#{value}"   
            else
                value.collect {|array_value| "#{key}=#{array_value}"}.join("&")
            end
        end
        url = NSURL.URLWithString(@base_url + resource + "?" + options_string.join("&") + @extra_params)
        request = NSMutableURLRequest.requestWithURL(url, cachePolicy:NSURLRequestReloadIgnoringCacheData, timeoutInterval:20.0)
        request.setValue("Basic #{@auth_token}", forHTTPHeaderField:"Authorization")
        return request
	end
    
end

class XMLResponse
    
    def initialize(delegate, method)
        @delegate = delegate
        @method = method
    end
    
    def connection(connection, didReceiveResponse:response)
        @response = response
        @downloadData = NSMutableData.data
    end
    
    def connection(connection, didReceiveData:data)
        @downloadData.appendData(data)
    end
    
    def connectionDidFinishLoading(connection)
        case @response.statusCode
            when 200...300
            xml = NSXMLDocument.alloc.initWithData(@downloadData,
                                                   options:NSXMLDocumentValidate,
                                                   error:nil)
            #@responseBody = NSString.alloc.initWithData(@downloadData, encoding:NSUTF8StringEncoding)
            #NSLog @responseBody
            if xml
                #NSLog "Methods: #{@delegate.class.class}"
                @delegate.method(@method).call(xml)
            end
            else
            NSLog "ERROR! #{@response.statusCode}"
            @delegate.method(@method).call(@response.statusCode)
        end
    end        
end

class DownloadResponse
    
    def initialize(path, id, delegate, method)
        @delegate = delegate
        @method = method
        @path = path
        @id = id
    end
    
    def connection(connection, didReceiveResponse:response)
        @response = response
        @downloadData = NSMutableData.data
    end
    
    def connection(connection, didReceiveData:data)
        @downloadData.appendData(data)
    end
    
    def connectionDidFinishLoading(connection)
        case @response.statusCode
            when 200...300
            @delegate.method(@method).call(@downloadData, @path, @id)
            else
            NSLog "Image response: #{@response.statusCode}"
        end
    end
    
end