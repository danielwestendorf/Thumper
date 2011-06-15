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
		borderWidth = 0.8
        # Set the window background to transparent
        x = bounds.origin.x + 0.8
		y = bounds.origin.y + 0.8
		full_width = bounds.size.width
        width = full_width - 1.6
		full_height = bounds.size.height
        height = full_height - 1.6
        rect = NSRect.new([x,y], [width, height])
        radius = height/2
		NSColor.lightGrayColor.set
        path = NSBezierPath.alloc
        path.setLineWidth(borderWidth)
        path.appendBezierPathWithRoundedRect(rect, xRadius: radius, yRadius: radius)
        path.fill
		NSColor.darkGrayColor.set
        path.stroke
        
        @progressPercent ||= 0.00
        progressWidth = width * (@progressPercent * 0.01)
		progressRect = NSRect.new([x,y],[progressWidth, height])
        fillPath = NSBezierPath.alloc
        fillPath.appendBezierPathWithRoundedRect(progressRect, xRadius: radius, yRadius: radius)
        fillPath.fill
        
        
	end
end 