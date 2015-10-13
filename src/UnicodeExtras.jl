module UnicodeExtras

using ICU

using Compat

export
    UnicodeText,
    decode,
    detect_encoding,
    encode,
    foldcase,
    set_locale, # from ICU
    titlecase

import Base: cmp,
    convert,
    endof,
    getindex,
    isequal,
    isless,
    length,
    lowercase,
    show,
    uppercase

## lowercase, uppercase, foldcase, titlecase ##
#
# Example:
#
#   using UnicodeExtras
#   uppercase("testingß")  # "TESTINGSS"
#   set_locale("tr")       # set locale to Turkish
#   uppercase("testingß")  # "TESTİNGSS"
#
# Note that "ß" gets converted to "SS" in the first call to uppercase,
# and "i" gets converted to "İ" (dotted capital I) in the second call
# after the locale is set to Turkish.
#

 foldcase(s::ASCIIString) = foldcase(utf8(s))
titlecase(s::ASCIIString) = titlecase(utf8(s))

 foldcase(s::UTF8String)  = ucasemap_utf8FoldCase(s)
lowercase(s::UTF8String)  = ucasemap_utf8ToLower(s)
uppercase(s::UTF8String)  = ucasemap_utf8ToUpper(s)
titlecase(s::UTF8String)  = ucasemap_utf8ToTitle(s)

 foldcase(s::UTF16String) = u_strFoldCase(s)
lowercase(s::UTF16String) = u_strToLower(s)
uppercase(s::UTF16String) = u_strToUpper(s)
titlecase(s::UTF16String) = u_strToTitle(s)

## UnicodeText ##

immutable UnicodeText
    data::Array{UInt16,1}
end

UnicodeText(s::ByteString) = UnicodeText(utf16(s).data)
UnicodeText(s::UTF16String) = UnicodeText(s.data)

convert(::Type{UTF8String},  t::UnicodeText) = utf8(utf16(t.data))
convert(::Type{UTF16String}, t::UnicodeText) = UTF16String(t.data)

cmp(a::UnicodeText, b::UnicodeText) = ucol_strcoll(ICU.collator, a.data, b.data)
# is this right?
cmp(t::UnicodeText, s::AbstractString) = cmp(UTF16String(t.data), s)
cmp(s::AbstractString, t::UnicodeText) = cmp(t, s)

endof(t::UnicodeText) = length(t)

isequal(a::UnicodeText, b::UnicodeText)    = cmp(a,b) == 0
isequal(a::UnicodeText, b::AbstractString) = cmp(a,b) == 0
isequal(a::AbstractString, b::UnicodeText) = cmp(a,b) == 0

isless(a::UnicodeText, b::UnicodeText)     = cmp(a,b) < 0
isless(a::UnicodeText, b::AbstractString)  = cmp(a,b) < 0
isless(a::AbstractString, b::UnicodeText)  = cmp(a,b) < 0

function length(t::UnicodeText)
    bi = ubrk_open(UBRK_CHARACTER, ICU.locale, t.data)
    n = 0
    while ubrk_next(bi) > 0
        n += 1
    end
    ubrk_close(bi)
    n
end

getindex(t::UnicodeText, i::Int) = getindex(t, i:i)
function getindex(t::UnicodeText, r::UnitRange{Int})
    bi = ubrk_open(UBRK_CHARACTER, ICU.locale, t.data)
    offset = 0
    for i = 1:first(r)-1
        offset = ubrk_next(bi)
        offset > 0 || break
    end
    a = offset + 1
    for i = 1:last(r)-first(r)+1
        offset = ubrk_next(bi)
        offset > 0 || break
    end
    b = offset
    ubrk_close(bi)
    SubString(UTF16String(t.data), a, b)
end

for f in (:foldcase,:lowercase,:titlecase,:uppercase)
    @eval ($f)(t::UnicodeText) = UnicodeText(($f)(utf16(t)))
end

show(io::IO, t::UnicodeText) = show(io, UTF16String(t.data))

## encodings ##

function transcode(src::Array{UInt8,1}, from::ASCIIString, to::ASCIIString)
    src_cnv = ucnv_open(from)
    dst_cnv = ucnv_open(to)
    src_buf = IOBuffer(src)
    dst_buf = IOBuffer()
    Base.ensureroom(dst_buf, length(src))
    pivot = ICU.UConverterPivot(16)
    while ucnv_convertEx(dst_cnv, src_cnv, dst_buf, src_buf, pivot)
        Base.ensureroom(dst_buf, dst_buf.size + length(src))
    end
    ucnv_close(src_cnv)
    ucnv_close(dst_cnv)
    takebuf_array(dst_buf)
end

function decode(b::Array{UInt8,1}, encoding::ASCIIString)
    bytestring(transcode(b, encoding, "utf8"))
end

function encode(s::ByteString, encoding::ASCIIString)
    transcode(s.data, "utf8", encoding)
end

function detect_encoding(b::Array{UInt8,1})
   cs = ucsdet_open()
   ucsdet_setText(cs, b)
   a = ucsdet_detectAll(cs)
   ret = ASCIIString[ucsdet_getName(x) for x in a]
   ucsdet_close(cs)
   ret
end

end # module
