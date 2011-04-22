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
            NSNotificationCenter.defaultCenter.postNotificationName('ThumperPreviousTrack', object:nil)
        elsif keyCode == 19
            NSNotificationCenter.defaultCenter.postNotificationName('ThumperNextTrack', object:nil)
        elsif keyCode == 16
            NSNotificationCenter.defaultCenter.postNotificationName('ThumperPlayToggle', object:nil)
        end
    end
    
end
