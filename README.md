UnicodeExtras
=============

[![Build Status](https://travis-ci.org/nolta/UnicodeExtras.jl.png)](https://travis-ci.org/nolta/UnicodeExtras.jl)

Installation
------------

    julia> Pkg.add("UnicodeExtras")

Usage
-----

### Case handling

This package extends Julia's builtin `uppercase` and `lowercase` functions,
and adds `titlecase` and `foldcase`.

    julia> uppercase("testingß")
    "TESTINGß"

    julia> using UnicodeExtras

    julia> uppercase("testingß")
    "TESTINGSS"

    julia> set_locale("tr")  # set locale to Turkish
    "tr"

    julia> uppercase("testingß")
    "TESTİNGSS"

Note that "ß" gets converted to "SS" after UnicodeExtras is loaded,
and "i" gets converted to "İ" (dotted capital I)
after the locale is set to Turkish.

### UnicodeText

In julia, a string is conceptually an array of unicode code points.
While well defined, this occasionally causes confusion because a single
code point doesn't necessarily correspond to what people perceive as a single
"character".

Take the following example:

```jlcon
julia> n1 = "noe\u0308l"
"noël"

julia> length(s)
5
```

Here, the `ë` "character" here consists of two code points: 'e' & '\u0308',
and so the length of the string is 5, not 4.

```jlcon
julia> noel1 = UnicodeText("noe\u0308l")
"noël"

julia> noel2 = UnicodeText("noël")
"noël"

julia> noel1.data
5-element Array{Uint16,1}:
 0x006e
 0x006f
 0x0065
 0x0308
 0x006c

julia> noel2.data
4-element Array{Uint16,1}:
 0x006e
 0x006f
 0x00eb
 0x006c

julia> noel1 == noel2
true

julia> length(noel1) == 4 == length(noel2)
true

julia> noel1[1:3]
"noë"
```

UnicodeText comparisons are locale sensitive:

```
julia> set_locale("de")  # german
"de"

julia> UnicodeText("Köpfe") < UnicodeText("Kypper")
true

julia> set_locale("sv")  # swedish
"sv"

julia> UnicodeText("Köpfe") < UnicodeText("Kypper")
false
```
