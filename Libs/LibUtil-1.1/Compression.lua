local MAJOR_VERSION = "LibUtil-1.1"
local MINOR_VERSION = 20502

local lib, minor = LibStub(MAJOR_VERSION, true)
if not lib or next(lib.Compression) or (minor or 0) > MINOR_VERSION then return end

local Util = lib
--- @class LibUtil.Compression
local Self = Util.Compression
local Class = LibStub("LibClass-1.0")
--- @type LibLogging
local Logging = LibStub("LibLogging-1.0")
--- @type LibDeflate
local LibDeflate = LibStub("LibDeflate")

local Encoder = Class('Encoder')
local LibDeflateEncoder = Class('LibDeflateEncoder', Encoder)

-- Base Encoder class
function Encoder:initialize(encodeFn, decodeFn)
    self.encodeFn = encodeFn or Util.Functions.Id
    self.decodeFn = decodeFn or Util.Functions.Id
end

function Encoder:encode(value)
    return self.encodeFn(value)
end

function Encoder:decode(value)
    return self.decodeFn(value)
end

-- LibDeflate
function LibDeflateEncoder:initialize()
    Encoder.initialize(
            self,
            function(v) return LibDeflate:EncodeForWoWAddonChannel(v) end,
            function(v) return LibDeflate:DecodeForWoWAddonChannel(v) end
    )
end

Self.EncoderType = {
    NoOp             = 1,
    LibDeflate       = 2,
}

local Encoders = {
    [Self.EncoderType.NoOp]        = Encoder(),
    [Self.EncoderType.LibDeflate]  = LibDeflateEncoder()
}

--- @class LibUtil.Compression.Compressor
local Compressor = Class('Compressor')
local LibDeflateCompressor = Class('LibDeflateCompressor', Compressor)

function Compressor:initialize(compressFn, decompressFn, encoder)
    self.compressFn = compressFn or Util.Functions.Id
    self.decompressFn = decompressFn or Util.Functions.Id
    self.encoder = encoder or Encoders[Self.EncoderType.NoOp]
end

function Compressor:GetName()
    return tostring(self.clazz):gsub("^class ", "")
end

function Compressor:LogPrefix(method)
    return format("%s:%s", self:GetName(), tostring(method))
end

function Compressor:compress(value, encode)
    if encode == nil or type(encode) ~= 'boolean' then encode = false end

    -- Logging:Trace("%s(%s) : length=%d", self:LogPrefix("compress"), tostring(encode), #value)
    local compressed, err = self.compressFn(value)
    if not compressed then
        Logging:Error("%s(%s) : Error encountered during compression - '%s'", self:LogPrefix("compress"), tostring(encode), tostring(err))
        return compressed, err
    end

    if encode then
        compressed, err = self.encoder:encode(compressed)
        if not compressed then
            Logging:Error("%s(%s) : Error encountered during encoding - '%s'", self:LogPrefix("compress"), tostring(encode), tostring(err))
            return compressed, err
        end
    end

    -- Logging:Trace("%s(%s) : size=%d", self:LogPrefix("compress"), tostring(encode), #compressed)
    return compressed
end

function Compressor:decompress(value, decode)
    if decode == nil or type(decode) ~= 'boolean' then decode = false end

    -- Logging:Trace("%s(%s) : length=%d", self:LogPrefix("decompress"), tostring(decode), #value)
    local decoded, err1 = nil, nil
    if decode then
        decoded, err1 = self.encoder:decode(value)
        if not decoded then
            Logging:Error("%s(%s) : Error encountered during decoding - '%s'", self:LogPrefix("decompress"), tostring(decode), tostring(err1))
            return decoded, err1
        end
    end

    local decompressed, err2 = self.decompressFn(decoded or value)
    if not decompressed then
        Logging:Error("%s(%s) : Error encountered during decompression - '%s'", self:LogPrefix("decompress"), tostring(decode), tostring(err2))
        return decompressed, err2
    end

    -- Logging:Trace("%s(%s) : size=%d", self:LogPrefix("decompress"), tostring(decode), #decompressed)
    return decompressed
end

-- uses LibDeflate
function LibDeflateCompressor:initialize()
    Compressor.initialize(
            self,
            function(v) return LibDeflate:CompressDeflate(v, {level = 9}) end,
            function(v) return LibDeflate:DecompressDeflate(v) end,
            Encoders[Self.EncoderType.LibDeflate]
    )
end

Self.CompressorType = {
    NoOp             = 1,
    LibDeflate       = 2,
}

local Compressors = {
    [Self.CompressorType.NoOp]            = Compressor(),
    [Self.CompressorType.LibDeflate]      = LibDeflateCompressor()
}

if _G.LibUtil_Testing then
    function Self.Encoders()
        return Util(Encoders):Copy()()
    end

    function Self.Compressors()
        return Util(Compressors):Copy()()
    end
end

function Self.GetCompressors(...)
    local c = Util.Tables.New()

    for n = 1, select("#", ...) do
        local key = select(n, ...)
        if not Compressors[key] then error(format("No compressor available for index '%s'", tostring(key))) end
        Util.Tables.Push(c, Compressors[key])
    end

    return c
end