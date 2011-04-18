class Connectivity    
    
    def initialize(parent)
        @parent = parent
        @connectivity_timer = NSTimer.scheduledTimerWithTimeInterval 5.0,
            target: self,
            selector: 'check_connectivity:',
            userInfo: nil,
            repeats: true
        check_connectivity(NSNotification.alloc.initWithName(nil, object:nil, userInfo:nil))
    end

    def check_connectivity(notification)
        @parent.subsonic.ping(self, :ping_response)
    end

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


end