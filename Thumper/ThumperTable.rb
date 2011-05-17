class ThumperTable < NSTableView
    attr_accessor :delegator

    def keyDown(event)
        characters = event.characters
        character = characters.characterAtIndex(0)
        if character == NSDeleteCharacter
            @delegator.pressed_delete
        elsif character == 97 && (event.modifierFlags & NSCommandKeyMask) == NSCommandKeyMask
            @delegator.select_all
        else
            super(event)
        end
    end

end