#
#  ThumperApplicaiton.rb
#  Thumper
#
#  Created by Daniel Westendorf on 4/8/11.
#  Copyright 2011 Daniel Westendorf. All rights reserved.
#

class ThumperApplicaiton < NSApplication
    def sendEvent(event)
        if event.type == NSSystemDefined && event.subtype == 8
            keyCode = (event.data1 & 0xFFFF0000) >> 16
            keyFlags = event.data1 & 0x0000FFFF
            keyState = (keyFlags & 0xFF00) >> 8 == 0xA
            mediaKeyPressed(keyCode) if keyState
            super(nil)
        else
            super(event)
        end
        
    end
    
    def mediaKeyPressed(keyCode)
        if keyCode == 20
            puts "Prev track"
            elsif keyCode == 19
            puts "Next track"
            elsif keyCode == 16
            puts "Play toggle"
        end
    end
end
