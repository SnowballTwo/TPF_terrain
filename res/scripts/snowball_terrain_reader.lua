local reader = {}

function reader.readByte( file )
    return string.byte( file:read(1) )
end

function reader.readShort( file )
    return reader.readByte(file) + reader.readByte(file) * 256
end

function reader.readString( file, length )
    return file:read( length )
end

return reader