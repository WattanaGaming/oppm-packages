local exgl = {
    proxy = nil, -- Proxy for GPU access.
    palette = {}, -- Color palette.
}

-- Make sure a GPU proxy is set.
function exgl:requireGPU()
    assert(self.proxy, "GPU proxy not present")
end

-- +---------------------------+
-- | BASIC RENDERING FUNCTIONS |
-- +---------------------------+

-- Convenience function.
-- Creates a new framebuffer and set it as active. Returns the index of the created framebuffer.
function exgl:beginFrame(width, height)
    self:requireGPU()
    local frameBufferIndex

    if width and height then
        frameBufferIndex = self.proxy.allocateBuffer(width, height)
    else
        frameBufferIndex = self.proxy.allocateBuffer()
    end
    self.proxy.setActiveBuffer(frameBufferIndex)

    return frameBufferIndex
end

-- Blit a framebuffer to the screen then free it from GPU memory.
function exgl:endFrame(bufferIndex)
    self:requireGPU()
    self.proxy.bitblt()
    self.proxy.freeBuffer(bufferIndex)
end

-- +------------------------+
-- | 2D RENDERING FUNCTIONS |
-- +------------------------+

-- Draw 2D graphics using the provided data and other parameters.
-- The data should be a table containing a list of all pixel colors with the length of width * height.
function exgl:drawGraphics(data, width, height, x, y, usePalette)
    self:requireGPU()
    assert(type(data) == "table", "Incorrect data type")
    assert(#data == (width * height), "Data length is not equal to width*height ("..(width*height)..")")
    assert(type(width) == "number", "Width value is not a number")
    assert(type(height) == "number", "Height value is not a number")
    x = x or 1
    y = y or 1
    usePalette = usePalette or false
    local oldBG = self.proxy.getBackground()
    
    local offsetX, offsetY = 0,0
    for _,color in ipairs(data) do
        if usePalette == true then
            assert(#self.palette > 0, "Invalid palette")
            assert(self.palette[color], "Invalid palette index")
            self.proxy.setBackground(self.palette[color])
        else
            self.proxy.setBackground(color)
        end
        self.proxy.set(x + offsetX, y + offsetY, " ")
        
        offsetX = offsetX + 1
        if offsetX == width then
            offsetX = 0
            offsetY = offsetY + 1
        end
    end
    self.proxy.setBackground(oldBG)
end

function exgl:blitGraphic(x, y, width, height, srcBuffer, srcX, srcY)
    local currentBuffer = self.proxy.getActiveBuffer()
    self.proxy.bitblt(currentBuffer, x, y, width, height, srcBuffer, srcX, srcY)
end

return exgl
