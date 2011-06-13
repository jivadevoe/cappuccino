/*
 * CTLine.j
 * CoreText
 *
 * Created by Nicholas Small.
 * Copyright 2011, 280 North, Inc.
 *
 * This library is free software; you can redistribute it and/or
 * modify it under the terms of the GNU Lesser General Public
 * License as published by the Free Software Foundation; either
 * version 2.1 of the License, or (at your option) any later version.
 *
 * This library is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
 * Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public
 * License along with this library; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA
 */

@import "CTRun.j"


kCTLineTruncationStart = 0;
kCTLineTruncationEnd = 1;
kCTLineTruncationMiddle = 2;

// Returns a CTLine
function CTLineCreateWithAttributedString(/* CPAttributedString */ aString)
{
    var line = {
        string: aString,
        runs: []
    };
    
    _CTLineCreateRuns(line);
    
    return line;
}

CTLineCreateWithAttributedString.displayName = @"CTLineCreateWithAttributedString";

// Returns a CTLine
function CTLineCreateTruncatedLine(/* CTLine */ aLine, /* float */ width, /* CTLineTruncationType */ truncationType, /* CTLine */ truncationToken)
{
    return aLine;
}

CTLineCreateTruncatedLine.displayName = @"CTLineCreateTruncatedLine";

// Returns a CTLine
function CTLineCreateJustifiedLine(/* CTline */ aLine, /* float */ justificationFactor, /* float */ width)
{
    return aLine;
}

CTLineCreateJustifiedLine.displayName = @"CTLineCreateJustifiedLine";

// Returns an index
function CTLineGetGlyphCount(/* CTLine */ aLine)
{
    return [aLine.string length];
}

CTLineGetGlyphCount.displayName = @"CTLineGetGlyphCount";

// Returns an array of CTGlyphRuns
function CTLineGetGlyphRuns(/* CTLine */ aLine)
{
    return aLine.runs;
}

CTLineGetGlyphRuns.displayName = @"CTLineGetGlyphRuns";

// Returns a CPRange
function CTLineGetStringRange(/* CTLine */ aLine)
{
    return CPCopyRange(aLine.range) || CPMakeRange(0, [aLine.string length])
}

CTLineGetStringRange.displayName = @"CTLineGetStringRange";

function CTLineGetPenOffsetForFlush(/* CTLine */ aLine, /* float */ flushFactor, /* float */ flushWidth)
{
    
}

CTLineGetPenOffsetForFlush.displayName = @"CTLineGetPenOffsetForFlush";

function CTLineDraw(/* CTLine */ aLine, /* CGContext */ aContext)
{
    var startPosition = aLine._startPosition = CGContextGetTextPosition(aContext),
        height = CTLineGetImageBounds(aLine, aContext).size.height;
    
    // FIXME: This is WRONG. This NEEDS to be in CGContext.
    CGContextSetTextPosition(aContext, startPosition.x, startPosition.y + height * 0.5);
    
    var runs = aLine.runs;
    for (var i = -1, count = runs.length; ++i < count;)
        CTRunDraw(runs[i], aContext);
    
    CGContextSetTextPosition(aContext, startPosition.x, startPosition.y + height);
}

CTLineDraw.displayName = @"CTLineDraw";

// Returns a CGRect
// Cheap
function CTLineGetImageBounds(/* CTLine */ aLine, /* CGContext */ aContext)
{
    if (aLine._imageBounds)
        return aLine._imageBounds;
    
    var runs = aLine.runs,
        width = 0.0,
        height = 0.0;
    
    for (var i = -1, count = runs.length; ++i < count;)
    {
        var runSize = CTRunGetImageBounds(runs[i], aContext).size;
        width += runSize.width;
        height = MAX(height, runSize.height);
    }
    
    return aLine._imageBounds = CGRectMake(0.0, 0.0, width, height);
}

CTLineGetImageBounds.displayName = @"CTLineGetImageBounds";

// Returns a JSObject: {width: float, ascent: float, descent: float, lineHeight: float}
// More expensive
function CTLineGetTypographicBounds(/* CTLine */ aLine)
{
    if (aLine._typographicBounds)
        return aLine._typographicBounds;
    
    var runs = aLine.runs,
        width = 0.0,
        ascent = 0.0,
        descent = 0.0,
        lineHeight = 0.0;
    
    for (var i = -1, count = runs.length; ++i < count;)
    {
        var runObject = CTRunGetTypographicBounds(runs[i]);
        width += runObject.width;
        ascent = MAX(ascent, runObject.ascent);
        descent = MAX(descent, runObject.descent);
        lineHeight = MAX(lineHeight, runObject.lineHeight);
    }
    
    return aLine._typographicBounds = {
        width: width,
        ascent: ascent,
        descent: descent,
        lineHeight: lineHeight
    };
}

CTLineGetTypographicBounds.displayName = @"CTLineGetTypographicBounds";

// Returns an index
function CTLineGetStringIndexForPosition(/* CTLine */ aLine, /* CGPoint */ aPoint)
{
    var runs = aLine.runs, x = aPoint.x, index = 0;
    for (var i = -1, count = runs.length; ++i < count;)
    {
        var run = runs[i],
            origins = run.glyphOrigins;
        
        for (var j = -1, jcount = origins.length; ++j < jcount;)
        {
            var origin = origins[j], next;
            if (j < jcount - 1)
                next = origins[j + 1];
            else if (i < count - 1)
                next = runs[i + 1].glyphOrigins[0];
            else
                return index++;
            
            if (x <= (next.x - origin.x) / 2 + origin.x)
                return index;
            
            index++;
        }
    }
}

CTLineGetStringIndexForPosition.displayName = @"CTLineGetStringIndexForPosition";

// Returns a float
function CTLineGetOffsetForStringIndex(/* CTLine */ aLine, /* int */ anIndex, /* float */ secondaryOffset)
{
    var runs = aLine.runs;
    for (var i = -1, count = runs.length; ++i < count;)
    {
        var run = runs[i], runRange = run.range;
        if (CPLocationInRange(anIndex, runRange))
            return run.glyphOrigins[anIndex - runRange.location];
    }
}

CTLineGetOffsetForStringIndex.displayName = @"CTLineGetOffsetForStringIndex";

function _CTLineCreateRuns(aLine)
{
    var string = aLine.string,
        runs = aLine.runs,
        rangeEntries = string._rangeEntries;
    
    for (var i = -1, count = rangeEntries.length; ++i < count;)
    {
        var rangeEntry = rangeEntries[i],
            range = rangeEntry.range,
            rangeString = [[string string] substringWithRange:range],
            attributes = rangeEntry.attributes;
        
        var run = _CTRunCreate(rangeString, attributes);
        run.range = range;
        
        runs.push(run);
    }
}

_CTLineCreateRuns.displayName = @"_CTLineCreateRuns";
