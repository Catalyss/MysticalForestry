function get_resource_tint(resource_name, resource_proto)
    if resource_proto.mining_visualisation_tint then
        return resource_proto.mining_visualisation_tint
    end

    if resource_proto.map_color then
        return resource_proto.map_color
    end

    if resource_proto.friendly_map_color then
        return resource_proto.friendly_map_color
    end

    if resource_proto.visualization_color then
        return resource_proto.visualization_color
    end

    if resource_proto.flow_color then
        return resource_proto.flow_color
    end

    return { r = 1, g = 1, b = 1, a = 1 }
end

function get_kwality_crsytal_icon(quality)
    local icon = { {
        icon = "__MysticalForestry__/graphics/template-prism.png",
        icon_size = 64,
        scale = 0.5,
        tint = quality.color,
    } }
    return icon
end

function get_master_crsytal_icon() --512
    local icons = {
    {
        icon = "__MysticalForestry__/graphics/master-prism.png",
        icon_size = 64
    },
    {
        icon = "__MysticalForestry__/graphics/master-prism-mask.png",
        icon_size = 64,
        tint = { r = 1, g = 1, b = 1, a = 0.6 },
        blend_mode = "additive"
    }
}
    return icons
end
