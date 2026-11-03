--
-- jk-ufw boot loader brand (the brand id stays "opnsense" so loader.conf keeps working)
--
local drawer = require("drawer")

local brand_jkufw = {
"   _ _                __          ",
"  (_) | __     _   _ / _|_      __",
"  | | |/ /____| | | | |_\\ \\ /\\ / /",
"  | |   <_____| |_| |  _|\\ V  V / ",
" _/ |_|\\_\\     \\__,_|_|   \\_/\\_/  ",
"|__/                              "
}

drawer.addBrand("opnsense", {
	graphic = brand_jkufw,
	shift = {x = 10, y = 1},
})

return true
