require 'base64'

module Subsonic
    attr_reader :albums, :songs, :artists
    
	def initialize(parent, base_url, username, password)
        @parent = parent
		@base_url = base_url
		@auth_token = Base64.encode64("#{username}:#{password}").strip
		@extra_params = "&f=xml&v=1.4.0&c=Thumper"
	end
	
	#response methods
	def ping_response(xml)
		if xml.class == NSXMLDocument
            @parent.status_label.stringValue = "Online" 
            NSLog "Online"
        else
            @parent.status_label.stringValue = "Offline"
            NSLog "Offline"
		end
		xml = nil
	end
	
	def albums_response(xml)
        @albums = []
        if xml.class == NSXMLDocument
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

            @parent.albums.count != 1 ? word = " Albums" : word = " Album"
            @parent.album_count_label.stringValue = @parent.albums.count.to_s + word
            @parent.albums_table_view.reloadData
            @parent.albums_table_view.enabled = true
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
        @parent.get_album_songs(@albums.first[:id]) if @albums.length == 1
	end
	
	def songs_response(xml)
        @songs = []
        if xml.class == NSXMLDocument
            songs = xml.nodesForXPath("subsonic-response", error:nil).first.nodesForXPath('directory', error:nil).first.nodesForXPath('child', error:nil)
            songs.each do |xml_song|
                attributeNames = ["id", "title", "artist", "coverArt", "parent", "isDir", "duration", "bitRate", "track", "year", "genre", "size", "suffix",
                                "album", "path", "size"]
                song = {}
                attributeNames.each do |name|
                    song[name.to_sym] = xml_song.attributeForName(name).stringValue unless xml_song.attributeForName(name).nil? 
                end
                song[:cover_art] = Dir.home + "/Library/Thumper/CoverArt/#{song[:coverArt]}.jpg"
                song[:album_id] = song[:parent]
                song[:bitrate] = song[:bitRate]
                song[:duration] = @parent.format_time(song[:duration].to_i)
                @songs << song if song[:isDir] == "false"
            end
        else
            NSLog "Invalid response from server"
        end
        xml = nil
        if @parent.albums[@parent.albums_table_view.selectedRow][:id] == @songs.first[:album_id]
            @parent.songs = @songs
            @parent.songs.count != 1 ? word = " Songs" : word = " Song"
            @parent.songs_count_label.stringValue = @songs.count.to_s + word
            @parent.songs_table_view.reloadData
            @parent.songs_table_view.enabled = true
        else

        end
        NSLog "Persisting songs to the DB"
        if DB[:songs].filter(:album_id => @songs.first[:album_id]).all.count < 1
            DB.transaction do
                @songs.each {|s| DB[:songs].insert(:id => s[:id], :title => s[:title], :artist => s[:artist], :duration => s[:duration], 
                                                   :bitrate => s[:bitrate], :track => s[:track], :year => s[:year], :genre => s[:genre],
                                                   :size => s[:size], :suffix => s[:suffix], :album => s[:album], :album_id => s[:album_id],
                                                   :cover_art => s[:cover_art], :path => s[:path]) } 
            end
        else
            Dispatch::Queue.new('com.qweef.db').async do
                @songs.each do |s|
                    return if DB[:songs].filter(:id => s[:id]).all.first 
                    DB[:songs].insert(:id => s[:id], :title => s[:title], :artist => s[:artist], :duration => s[:duration], 
                                       :bitrate => s[:bitrate], :track => s[:track], :year => s[:year], :genre => s[:genre],
                                       :size => s[:size], :suffix => s[:suffix], :album => s[:album], :album_id => s[:album_id],
                                       :cover_art => s[:cover_art], :path => s[:path])
                    NSLog "Added Album: #{a[:title]}"
                end
            end
        end
        NSLog "All songs presisted to the DB"
	end
	
	def artists_response(xml)
        @artists = []
		if xml.class == NSXMLDocument
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
            Dispatch::Queue.new('com.qweef.db').async do
                @artists.each do |a|
                    return if DB[:artists].filter(:id => a[:id]).all.first 
                    DB[:artists].insert(:id => a[:id], :name => a[:name])
                    NSLog "Added Artist: #{a[:name]}"
                end
            end
        end
        NSLog "All Artists presisted to the DB"
	end
    
    def stream_response()

    end
    
    def image_response(data, path)
        response = data.writeToFile(path, atomically:true)
        @parent.albums_table_view.reloadData
    end
	
	
	#Actual data request methods
	def ping(delegate, method)
        request = build_request("/rest/ping.view", {})
        NSURLConnection.connectionWithRequest(request, delegate:Subsonic::XMLResponse.new(delegate, method))
	end
	
	def getLicense(delegate, method)
        request = build_request('/rest/getLicense.view', {})
        NSURLConnection.connectionWithRequest(request, delegate:Subsonic::XMLResponse.new(delegate, method))
	end
	
	def artists(delegate, method)
        request = build_request('/rest/getIndexes.view', {})
        NSURLConnection.connectionWithRequest(request, delegate:Subsonic::XMLResponse.new(delegate, method))
	end
	
	def albums(id, delegate, method)
        request = build_request('/rest/getMusicDirectory', {:id => id})
        NSURLConnection.connectionWithRequest(request, delegate:Subsonic::XMLResponse.new(delegate, method))
	end
	
	def songs(id, delegate, method)
        request = build_request('/rest/getMusicDirectory', {:id => id})
        NSURLConnection.connectionWithRequest(request, delegate:Subsonic::XMLResponse.new(delegate, method))
	end
    
    def cover_art(id, delegate, method)
        request = build_request('/rest/getCoverArt.view', {:id => id})
        path = Dir.home + "/Library/Thumper/CoverArt/#{id}.jpg"
        NSURLConnection.connectionWithRequest(request, delegate:Subsonic::ImageResponse.new(delegate, method, path))
    end
    
    def stream_audio(id, delegate, method)
        
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
                    @delegate.method(@method).call(xml)
                end
            else
                @delegate.method(@method).call(@response.statusCode)
            end
        end

        
    end
    
    class ImageResponse
        
        def initialize(delegate, method, path)
            @delegate = delegate
            @method = method
            @path = path
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
                @delegate.method(@method).call(@downloadData, @path)
            else
                NSLog "Image response: #{@response.statusCode}"
                @delegate.method(@method).call(@response.statusCode)
            end
        end
        
    end
    
    class StreamResponse
        
        def initialize(delegate, method)
            NSLog "initialized download"
            @delegate = delegate
            @method = method
        end
        
        def connection(connection, didReceiveResponse:response)
            @response = response
            @downloadData = NSMutableData.data
        end
        
        def connection(connection, didReceiveData:data)
            @movie = QTMovie.alloc.initWithData(@downloadData) unless @movie
            NSLog "#{@movie.class}"
            @downloadData.appendData(data)
        end
        
        def connectionDidFinishLoading(connection)
            NSLog "got all the data"
            case @response.statusCode
            when 200...300
                @delegate.method(@method).call(@downloadData)
            else
                NSLog "Stream response: #{@response.statusCode}"
                @delegate.method(@method).call(@response.statusCode)
            end
        end
        
    end
	
	
	private
	
	def build_request(resource, options)
        options_string = options.collect {|key, value| "#{key}=#{value}"}.join("&")
        url = NSURL.URLWithString(@base_url + resource + "?" + options_string + @extra_params)
        request = NSMutableURLRequest.requestWithURL(url)
        request.setValue("Basic #{@auth_token}", forHTTPHeaderField:"Authorization")
        return request
	end
    
end