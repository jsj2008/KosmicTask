//
// jscocoa-ext.js
//
// JSCocoa extensions as used by KosmicTask
//

// override default JSCocoa implementation
function log(str)
{
    __jsc__.qlog_('' + str)
}

// explicit quiet log
function qlog(str)
{
    __jsc__.qlog_('' + str)
}

// verbose log uses the default JSCocoa implementation
function vlog(str)
{
    __jsc__.log_('' + str)
}
