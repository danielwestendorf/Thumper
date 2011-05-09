class ThumperTable < NSTableView
    attr_accessor :delegator

    def keyDown(event)
        characters = event.charactersIgnoringModifiers.characterAtIndex(0)
        if characters == NSDeleteCharacter
            @delegator.pressed_delete
        else
            super(event)
        end
    end

end