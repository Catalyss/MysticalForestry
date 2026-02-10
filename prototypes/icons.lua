
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

    return {r=0, g=0, b=0, a=0.5}
end
