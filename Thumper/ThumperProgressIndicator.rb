#
#  ThumperProgressIndicator.rb
#  Thumper
#
#  Created by Daniel Westendorf on 4/14/11.
#  Copyright 2011 Daniel Westendorf. All rights reserved.
#


class ThumperProgressIndicator < NSView
	attr_accessor :progressPercent
	attr_accessor :parent
	
	def mouseDown(event)
		point = convertPoint(event.locationInWindow, fromView: nil)
		click_percent = point.x/bounds.size.width
		duration = @parent.playing_song_object.duration.timeValue/@parent.playing_song_object.duration.timeScale.to_f
		new_time = duration * click_percent
		@parent.playing_song_object.setCurrentTime(QTTime.new(new_time, 1, false))
	end
	
    def drawRect(rect)
		borderWidth = 1
        # Set the window background to transparent
        x = bounds.origin.x
		y = bounds.origin.y
		width = bounds.size.width
		height = bounds.size.height 
		NSColor.lightGrayColor.set
		NSRectFill(bounds)
		NSColor.darkGrayColor.set
		NSFrameRectWithWidth(bounds, borderWidth)
		@progressPercent ||= 0.00
		progressWidth = width * (@progressPercent * 0.01)
		progressRect = NSRect.new([x,y],[progressWidth, height])
		NSRectFill(progressRect)
	end
end 