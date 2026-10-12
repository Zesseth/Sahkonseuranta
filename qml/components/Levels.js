// SPDX-License-Identifier: AGPL-3.0-or-later
//
// Shared price-level helpers: the level of a price for the given
// thresholds, and the color of each level. Used by MainPage,
// PriceGraph and PriceBall so thresholds and colors live in one place.
//
// Levels: 0 = cheap, 1 = middle, 2 = expensive

.pragma library

var greenColor = "#2ecc71"
var yellowColor = "#f1c40f"
var redColor = "#e74c3c"

function levelOf(price, cheap, expensive) {
    if (price <= cheap)
        return 0
    if (price >= expensive)
        return 2
    return 1
}

function levelColor(level) {
    if (level === 0)
        return greenColor
    if (level === 2)
        return redColor
    return yellowColor
}

function colorOf(price, cheap, expensive) {
    return levelColor(levelOf(price, cheap, expensive))
}
