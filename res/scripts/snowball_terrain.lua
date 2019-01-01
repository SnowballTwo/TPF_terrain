local transf = require "transf"
local vec3 = require "vec3"
local reader = require "snowball_terrain_reader"
local polygon = require "snowball_terrain_polygon"
local plan = require "snowball_terrain_planner"

local terrain = {}

terrain.markerStore = nil
terrain.finisherStore = nil
terrain.lastMarker = nil
terrain.markerId = "asset/snowball_terrain_marker.mdl"
terrain.finisherId = "asset/snowball_terrain_finisher.mdl"

function terrain.getFolderName(file)
    return file:match("^(.+/).+$")
end

function terrain.getObjects()
    if not terrain.markerStore then
        terrain.markerStore = {}
    end
    if not terrain.finisherStore then
        terrain.finisherStore = {}
    end

    plan.updateEntityLists(terrain.markerId, terrain.markerStore, terrain.finisherId, terrain.finisherStore)    
end

function terrain.createDisplacementMap(file)
    local map = assert(io.open(file, "rb"))
    local result = {}

    result.idLength = reader.readByte(map)
    result.paletteType = reader.readByte(map)
    result.imageType = reader.readByte(map)
    result.paletteStart = reader.readShort(map)
    result.paletteLength = reader.readShort(map)
    result.paletteEntryLength = reader.readByte(map)
    result.x = reader.readShort(map)
    result.x = reader.readShort(map)
    result.w = reader.readShort(map)
    result.h = reader.readShort(map)
    result.bpp = reader.readByte(map)
    result.imageAttributes = reader.readByte(map)

    if result.idLength > 0 then
        result.id = reader.readString(map, idLength)
    end

    if (result.paletteType > 0 and result.paletteLength > 0) then
        result.palette = reader.readString(map, result.paletteLength)
    end

    result.data = {}

    local min = nil
    local max = nil
    local average = 0
    for py = 1, result.h do
        for px = 1, result.w do
            if not result.data[px] then
                result.data[px] = {}
            end

            local p = reader.readByte(map)

            result.data[px][py] = p

            average = average + p

            if not min or min > p then
                min = p
            end
            if not max or max < p then
                max = p
            end
        end
    end

    result.average = average / (result.w * result.h)
    result.min = min
    result.max = max

    return result
end

function terrain.getPolygon()
    local polygon = {}

    for i = 1, #terrain.markerStore do
        local marker = terrain.markerStore[i]
        polygon[#polygon + 1] = {marker.position[1], marker.position[2], marker.position[2]}
    end

    if #polygon > 0 then
        return polygon
    else
        return nil
    end
end

function terrain.plan(result, ground_scan)
    terrain.getObjects()

    for i = 1, #terrain.finisherStore do
        local finisher = terrain.finisherStore[i]
        game.interface.bulldoze(finisher.id)
    end

    terrain.finisherStore = {}

    for i = 1, #terrain.markerStore + 1 do
        result.models[#result.models + 1] = {
            id = terrain.markerId,
            transf = {1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1}
        }
    end

    local poly = terrain.getPolygon(terrain.markerStore)
    local color = {0.8, 0.8, 0.8, 1}

    if poly and #poly > 2 then
        local bounds = polygon.getBounds(poly)

        if (bounds.width / ground_scan * bounds.height / ground_scan) > 1000000 then
            color = {1.0, 0.2, 0.2, 1}
        elseif (bounds.width / ground_scan * bounds.height / ground_scan) > 100000 then
            color = {1.0, 0.8, 0.2, 1}
        end
    end
    if poly then
        if #poly == 1 then
            local zone = {
                polygon = {{poly[1][1] - 5, poly[1][2], poly[1][3]}, {poly[1][1] + 5, poly[1][2], poly[1][3]}},
                draw = true,
                drawColor = color
            }
            game.interface.setZone("snowball_terrain_displacement_zone", zone)
        else
            local zone = {polygon = poly, draw = true, drawColor = color}
            game.interface.setZone("snowball_terrain_displacement_zone", zone)
        end
    end
end

function terrain.reset(result)
    result.models[#result.models + 1] = {
        id = terrain.finisherId,
        transf = {0.01, 0, 0, 0, 0, 0.01, 0, 0, 0, 0, 0.01, 0, 0, 0, 0, 1}
    }

    game.interface.setZone("snowball_terrain_displacement_zone", nil)

    if not terrain.markerStore then
        return
    end

    for i = 1, #terrain.markerStore do
        local marker = terrain.markerStore[i]
        game.interface.bulldoze(marker.id)
    end

    terrain.markerStore = {}
end

function terrain.plant(result, material, height, texture_scan, ground_scan, overlay)
    result.models[#result.models + 1] = {
        id = terrain.finisherId,
        transf = {1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1}
    }

    if not terrain.markerStore then
        return
    end

    local points = terrain.getPolygon()
    game.interface.setZone("snowball_terrain_displacement_zone", nil)

    for i = 1, #terrain.markerStore do
        local marker = terrain.markerStore[i]
        game.interface.bulldoze(marker.id)
    end

    terrain.markerStore = {}

    if (not points) or (#points < 3) then
        return result
    end

    local bounds = polygon.getBounds(points)

    local area = bounds.width * bounds.height
    if not area or area < 1e-6 then
        return result
    end

    game.interface.buildConstruction(
        "asset/snowball_terrain_displacement_patch.con",
        {points = points, material = material, height = height, texture_scan = texture_scan, ground_scan = ground_scan, overlay = overlay},
        {1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1}
    )
end

return terrain
