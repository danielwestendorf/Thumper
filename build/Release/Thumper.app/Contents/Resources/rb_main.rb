#
#  rb_main.rb
#  Thumper
#
#  Created by Daniel Westendorf on 4/2/11.
#  Copyright (c) 2011 Daniel Westendorf. All rights reserved.
#

# Loading the Cocoa framework. If you need to load more frameworks, you can
# do that here too.
framework 'Cocoa'
framework 'QTKit'
require 'yaml'

applicaitonDirectory = Dir.home << '/Library/Thumper'
Dir.mkdir(applicaitonDirectory) unless File.exists?(applicaitonDirectory)
Dir.mkdir(applicaitonDirectory + '/CoverArt') unless File.exists?(applicaitonDirectory + '/CoverArt')
# Loading all the Ruby project files.
main = File.basename(__FILE__, File.extname(__FILE__))
dir_path = NSBundle.mainBundle.resourcePath.fileSystemRepresentation
Dir.glob(File.join(dir_path, '*.{rb,rbo}')).map { |x| File.basename(x, File.extname(x)) }.uniq.each do |path|
  if path != main
    require(path)
  end
end

# Starting the Cocoa main loop.
NSApplicationMain(0, nil)
