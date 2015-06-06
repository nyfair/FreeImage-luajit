-- The file is in public domain
-- nyfair (nyfair2012@gmail.com)

local ffi = require 'ffi'
local filua = ffi.load('freeimage')
ffi.cdef[[
	typedef struct { uint8_t b, g, r, a; } RGBA;
	
	void*  FreeImage_Load(int, const char*, int);
	void*  FreeImage_LoadU(int, const char*, int);
	int  FreeImage_Save(int, void*, const char*, int);
	int  FreeImage_SaveU(int, void*, const char*, int);
	void*  FreeImage_Clone(void*);
	void  FreeImage_Unload(void*);
	void*  FreeImage_EnlargeCanvas(void*, int, int, int, int, RGBA*, int);
	void*  FreeImage_Allocate(int, int, int, unsigned, unsigned, unsigned);
	
	unsigned  FreeImage_GetBPP(void*);
	unsigned  FreeImage_GetWidth(void*);
	unsigned  FreeImage_GetHeight(void*);
	unsigned  FreeImage_GetDotsPerMeterX(void*);
	unsigned  FreeImage_GetDotsPerMeterY(void*);
	void  FreeImage_SetDotsPerMeterX(void*, unsigned);
	void  FreeImage_SetDotsPerMeterY(void*, unsigned);
	int  FreeImage_GetFIFFromFilename(const char*);
	int  FreeImage_GetFIFFromFilenameU(const char*);
	int  FreeImage_GetFileType(const char*, int);
	int  FreeImage_GetFileTypeU(const char*, int);
	RGBA*  FreeImage_GetPalette(void*);
	void*  FreeImage_SetTransparentIndex(void*, int);
	
	void*  FreeImage_ConvertToGreyscale(void*);
	void*  FreeImage_ConvertTo24Bits(void*);
	void*  FreeImage_ConvertTo32Bits(void*);
	
	void*  FreeImage_Rotate(void*, double, RGBA*);
	int  FreeImage_FlipHorizontal(void*);
	int  FreeImage_FlipVertical(void*);
	void*  FreeImage_Rescale(void*, int, int, int);
	int  FreeImage_JPEGTransform(const char*, const char*, int, int);
	int  FreeImage_JPEGCrop(const char *, const char*, int, int, int, int);
	
	void*  FreeImage_Copy(void*, int, int, int, int);
	int  FreeImage_Paste(void*, void*, int, int, int);
	void*  FreeImage_CreateView(void*, int, int, int, int);
	void*  FreeImage_Composite(void*, int, RGBA*, void*);
	int  FreeImage_GetPixelColor(void*, unsigned, unsigned, RGBA*);
	int  FreeImage_SetPixelColor(void*, unsigned, unsigned, RGBA*);
	void*  FreeImage_GetChannel(void*, int);
	int  FreeImage_SetChannel(void*, void*, int);
	int  FreeImage_SwapColors(void*, RGBA*, RGBA*, int);
	int  FreeImage_Invert(void*);
]]

-- helper
if ffi.os == 'Windows' then
	require 'fswin'

	function getfmt(name)
		local fmt = filua.FreeImage_GetFIFFromFilenameU(u2w(name))
		if fmt > -1 then
			return fmt
		else
			return filua.FreeImage_GetFileTypeU(u2w(name), 0)
		end
	end

	function open(name, flag)
		local fmt = getfmt(name)
		return filua.FreeImage_LoadU(fmt, u2w(name), flag or 0)
	end

	function save(img, name, flag)
		local fmt = getfmt(name)
		return filua.FreeImage_SaveU(fmt, img, u2w(name), flag or 0)
	end
else
	require 'fsposix'

	function getfmt(name)
		local fmt = filua.FreeImage_GetFIFFromFilename(name)
		if fmt > -1 then
			return fmt
		else
			return filua.FreeImage_GetFileType(name, 0)
		end
	end

	function open(name, flag)
		local fmt = getfmt(name)
		return filua.FreeImage_Load(fmt, name, flag or 0)
	end

	function save(img, name, flag)
		local fmt = getfmt(name)
		return filua.FreeImage_Save(fmt, img, name, flag or 0)
	end
end

function stripext(fn)
	local idx = fn:match('.+()%..+$')
	if idx then
		return fn:sub(1, idx - 1)
	else
		return fn
	end
end

function clone(img)
	return filua.FreeImage_Clone(img)
end

function free(img)
	filua.FreeImage_Unload(img)
end

function color(r, g, b, a)
	local color = ffi.new('RGBA[?]', 1)
	color[0].b= b or 0
	color[0].g= g or 0
	color[0].r= r or 0
	color[0].a= a or 0
	return color
end

function enlarge(img, left, top, right, bottom, rgba)
	return filua.FreeImage_EnlargeCanvas(img, left, top, right, bottom, rgba or color(), 0)
end

function newimg(width, height, bpp, r, g, b)
	return filua.FreeImage_Allocate(width, height, bpp or 24, r or 0, g or 0, b or 0)
end

-- Common Info
function getbpp(img)
	return filua.FreeImage_GetBPP(img)
end

function getw(img)
	return filua.FreeImage_GetWidth(img)
end

function geth(img)
	return filua.FreeImage_GetHeight(img)
end

function getdpi(img)
	local x = filua.FreeImage_GetDotsPerMeterX(img)
	local y = filua.FreeImage_GetDotsPerMeterY(img)
	return math.floor(x*0.0254+0.5), math.floor(y*0.0254+0.5)
end

function setdpi(img, x, y)
	filua.FreeImage_SetDotsPerMeterX(img, x/0.0254)
	filua.FreeImage_SetDotsPerMeterY(img, y/0.0254)
end

function getpixel(img, x, y, rgba)
	filua.FreeImage_GetPixelColor(img, x, y, rgba)
end

function setpixel(img, x, y, rgba)
	filua.FreeImage_SetPixelColor(img, x, y, rgba)
end

function getchannel(img, channel)
	return filua.FreeImage_GetChannel(img, channel)
end

function setchannel(dst, src, channel)
	return filua.FreeImage_SetChannel(dst, src, channel)
end

function swapcolor(img, fromcolor, tocolor)
	filua.FreeImage_SwapColors(img, fromcolor or color(0,0,0,0), tocolor or color(0,0,0,255), 0)
end

function invert(img)
	filua.FreeImage_Invert(img)
end

function greyalpha(back, front, channel)
	local b
	if getbpp(back) == 32 then
		b = clone(back)
	else
		b = to32(back)
	end
	if getbpp(front) == 8 then
		setchannel(b, front, 4)
	else
		local f = getchannel(front, channel or 2)
		invert(f)
		setchannel(b, f, 4)
		free(f)
	end
	return b
end

function imggreyalpha(img)
	local l = copy(img, 0, 0, getw(img)/2, geth(img))
	local r = copy(img, getw(img)/2, 0, getw(img), geth(img))
	local b = greyalpha(l, r)
	free(l)
	free(r)
	return b
end

function coloralpha(img, r, g, b)
	local a
	local bpp = getbpp(img)
	if bpp == 32 or bpp == 8 then
		a = clone(img)
	else
		a = to32(img)
	end
	bpp = getbpp(a)
	if bpp == 32 then
		swapcolor(a, color(r,g,b,0), color(r,g,b,255))
	else
		local c = filua.FreeImage_GetPalette(img)
		for i = 0, 255 do
			if c[i].r == r and c[i].g == g and c[i].b == b then
				filua.FreeImage_SetTransparentIndex(a, i)
				break
			end
		end
		
	end
	return a
end

-- Composite
function copy(img, left, top, right, bottom)
	return filua.FreeImage_Copy(img, left, top, right, bottom)
end

function paste(back, front, left, top, alpha)
	filua.FreeImage_Paste(back, front, left, top, alpha or 255)
end

function ref(img, left, top, right, bottom)
	return filua.FreeImage_CreateView(img, left, top, right, bottom)
end

-- alpha composite
function composite(back, front)
	return filua.FreeImage_Composite(front, 0, nil, back)
end

function to8(src)
	return filua.FreeImage_ConvertToGreyscale(src)
end

function to24(src)
	return filua.FreeImage_ConvertTo24Bits(src)
end

function to32(src)
	return filua.FreeImage_ConvertTo32Bits(src)
end

-- File-based process function
function convert(src, dst, flag)
	if src:find('*') then
		for k,v in ipairs(ls(src)) do
			local img = open(v)
			save(img, stripext(v)..'.'..dst, flag)
			free(img)
		end
	else
		local img = open(src)
		save(img, dst, flag)
		free(img)
	end
end

function convbpp(src, bpp, dst, flag)
	if bpp==24 or bpp==32 or bpp==8 then
		if src:find('*') then
			if dst == nil then
				dst = 'bmp'
			end
			for k,v in ipairs(ls(src)) do
				local img = open(v)
				local out
				if bpp == 24 then out = to24(img)
				elseif bpp == 32 then out = to32(img)
				else out = to8(img)
				end
				save(out, stripext(v)..'.'..dst, flag)
				free(img)
				free(out)
			end
		else
			if dst == nil then
				dst = src
			end
			local img = open(src)
			local out
			if bpp == 24 then out = to24(img)
			elseif bpp == 32 then out = to32(img)
			else out = to8(img)
			end
			save(out, dst, flag)
			free(img)
			free(out)
		end
	end
end

function combine(back, front, dst, left, top, flag)
	local img1 = open(back)
	local img2 = open(front)
	paste(img1, img2, left, top)
	save(img1, dst, flag)
	free(img1)
	free(img2)
end

function combinealpha(back, front, dst, flag)
	local img1 = open(back)
	local img2 = open(front)
	local img3 = composite(img2, img1)
	save(img3, dst, flag)
	free(img1)
	free(img2)
	free(img3)
end

function rotate(src, degree, dst, flag, rgba)
	if dst == nil then
		dst = stripext(src)..'_rotate.bmp'
	end
	local img = open(src)
	local out = filua.FreeImage_Rotate(img, degree, rgba or color())
	save(out, dst, flag)
	free(img)
	free(out)
end

function scale(src, width, height, filter, dst, flag)
	if dst == nil then
		dst = stripext(src)..'_thumb.bmp'
	end
	local img = open(src)
	local out = filua.FreeImage_Rescale(img, width, height, filter or 5)
	save(out, dst, flag)
	free(img)
	free(out)
end

function fliph(src, dst, flag)
	if dst == nil then
		dst = stripext(src)..'_fliph.bmp'
	end
	local img = open(src)
	filua.FreeImage_FlipHorizontal(img)
	save(img, dst, flag)
	free(img)
end

function flipv(src, dst, flag)
	if dst == nil then
		dst = stripext(src)..'_flipv.bmp'
	end
	local img = open(src)
	filua.FreeImage_FlipVertical(img)
	save(img, dst, flag)
	free(img)
end

function jpgcrop(src, left, top, right, bottom, dst)
	if dst == nil then
		dst = stripext(src)..'_crop.jpg'
	end
	filua.FreeImage_JPEGCrop(src, dst, left, top, right, bottom)
end

function jpgtran(src, func, dst, perfect)
	if dst == nil then
		dst = stripext(src)..'_tran.jpg'
	end
	filua.FreeImage_JPEGTransform(src, dst, func, perfect or 0)
end

function splitw(src, num)
	local img = open(src)
	local width = getw(img) / num
	local height = geth(img)
	local bpp = getbpp(img)
	for x = 1, num do
		local imgx = newimg(width, height, bpp)
		local tmp = ref(img, width*(x-1), 0, width*x, height)
		paste(imgx, tmp, 0, 0)
		save(imgx, stripext(src)..'_'..tostring(x)..'.bmp')
		free(tmp)
		free(imgx)
	end
	free(img)
end

function splith(src, num)
	local img = open(src)
	local width = getw(img)
	local height = geth(img) / num
	local bpp = getbpp(img)
	for y = 1, num do
		local imgy = newimg(width, height, bpp)
		local tmp = ref(img, 0, height*(y-1), width, height*y)
		paste(imgy, tmp, 0, 0)
		save(imgy, stripext(src)..'_'..tostring(y)..'.bmp')
		free(tmp)
		free(imgy)
	end
	free(img)
end

function mergew(x1, x2)
	local img1 = open(x1)
	local img2 = open(x2)
	local height = geth(img1)
	local width = getw(img1) + getw(img2) - offset or 0
	local img = newimg(width, height, getbpp(img1))
	paste(img, img1, 0, 0)
	paste(img, img2, getw(img1) - offset or 0, 0)
	save(img, stripext(x1)..'_'..stripext(x2)..'.bmp')
	free(img)
	free(img1)
	free(img2)
end

function mergews(x1, x2, offset)
	for k1,v1 in ipairs(ls(x1)) do
		for k2,v2 in ipairs(ls(x2)) do
			mergew(v1, v2, offset)
		end
	end
end

function mergeh(y1, y2, offset)
	local img1 = open(y1)
	local img2 = open(y2)
	local height = geth(img1) + geth(img2) - offset or 0
	local width = getw(img1)
	local img = newimg(width, height, getbpp(img1))
	paste(img, img1, 0, 0)
	paste(img, img2, 0, geth(img1) - offset or 0)
	save(img, stripext(y1)..'_'..stripext(y2)..'.bmp')
	free(img)
	free(img1)
	free(img2)
end

function mergehs(y1, y2, offset)
	for k1,v1 in ipairs(ls(y1)) do
		for k2,v2 in ipairs(ls(y2)) do
			mergeh(v1, v2, offset)
		end
	end
end
