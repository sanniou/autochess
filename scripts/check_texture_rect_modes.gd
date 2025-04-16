extends SceneTree

func _init():
    print("TextureRect expand_mode values:")

    # Create a TextureRect instance to check its properties
    var texture_rect = TextureRect.new()

    # Print available expand_mode values
    print("Available expand_mode values:")

    # Get the property information for expand_mode
    var property_info = null
    for prop in texture_rect.get_property_list():
        if prop.name == "expand_mode":
            property_info = prop
            break

    if property_info and property_info.has("class_name") and property_info.has("hint_string"):
        var hint_string = property_info.hint_string
        print("Hint string: ", hint_string)

        # Parse the hint string to get enum values
        var values = hint_string.split(",")
        for value in values:
            print("- " + value.strip_edges())
    else:
        print("Could not find expand_mode property info")

    # Clean up
    texture_rect.free()
    quit()
