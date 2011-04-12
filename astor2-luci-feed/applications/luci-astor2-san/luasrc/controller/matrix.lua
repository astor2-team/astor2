--[[
  aStor2 -- storage area network configurable via Web-interface
  Copyright (C) 2009-2011 ETegro Technologies, PLC
                          Vladimir Petukhov <vladimir.petukhov@etegro.com>
                          Sergey Matveev <stargrave@stargrave.org>
  
  This program is free software: you can redistribute it and/or modify
  it under the terms of the GNU Affero General Public License as
  published by the Free Software Foundation, either version 3 of the
  License, or (at your option) any later version.
  
  This program is distributed in the hope that it will be useful,
  but WITHOUT ANY WARRANTY; without even the implied warranty of
  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
  GNU Affero General Public License for more details.
  
  You should have received a copy of the GNU Affero General Public License
  along with this program.  If not, see <http://www.gnu.org/licenses/>.
]]--

local M = {}

common = require( "astor2.common" )
lvm = require( "astor2.lvm" )
einarc = require( "astor2.einarc" )

function M.gcd( x, y )
	if y == 0 then return math.abs( x ) end
	return M.gcd( y, x % y )
end

function M.lcm( x, y )
	if x == 0 and y == 0 then return 0 end
	return math.abs( x * y ) / M.gcd( x, y )
end

function M.overall( data )
	local highlights = {
		left = false,
		top = false,
		right = false,
		bottom = false
	}
	local physicals = data.physicals or {}
	local logicals = data.logicals or {}
	local physicals_free = common.deepcopy( physicals )
	local matrix = {}
	local current_line = 1

	for logical_id, logical in pairs( logicals ) do
		local physicals_quantity = #common.keys( logical.physicals )
		local logical_volumes_quantity = #common.keys( logical.logical_volumes or {} )
		local lines_quantity = physicals_quantity
		if logical_volumes_quantity ~= 0 then
			lines_quantity = M.lcm(
				physicals_quantity,
				logical_volumes_quantity
			)
		end
		local future_line = current_line + lines_quantity

		-- Fillup an empty lines
		for i = current_line, future_line - 1 do
			matrix[ i ] = {}
		end

		-- Fillup logical
		matrix[ current_line ].logical = logical
		matrix[ current_line ].logical.rowspan = lines_quantity
		matrix[ current_line ].logical.highlight = common.deepcopy( highlights )

		-- Fillup physicals
		for physical_id, physical in pairs( logical.physicals ) do
			if physicals[ physical_id ].state == tostring( logical_id ) then
				physicals[ physical_id ].state = "allocated"
			end
			logical.physicals[ physical_id ] = physicals[ physical_id ]
			physicals_free[ physical_id ] = nil
		end
		local physical_rowspan = lines_quantity / physicals_quantity
		for i, physical in ipairs( einarc.Physical.sort( logical.physicals ) ) do
			local offset = current_line + ( i - 1 ) * physical_rowspan
			matrix[ offset ].physical = physical
			matrix[ offset ].physical.rowspan = physical_rowspan
			matrix[ offset ].physical.highlight = common.deepcopy( highlights )
		end

		-- Fillup logical volumes
		local logical_volume_names = common.keys( logical.logical_volumes or {} )
		table.sort( logical_volume_names )
		local logical_volume_rowspan = lines_quantity / logical_volumes_quantity
		for i, logical_volume_name in ipairs( logical_volume_names ) do
			local offset = current_line + ( i - 1 ) * logical_volume_rowspan
			matrix[ offset ].logical_volume = logical.logical_volumes[ logical_volume_name ]
			matrix[ offset ].logical_volume.rowspan = logical_volume_rowspan
			matrix[ offset ].logical_volume.highlight = common.deepcopy( highlights )
		end

		-- Perform needed borders highlighting
		matrix[ current_line ].physical.highlight.top = true
		matrix[ current_line ].physical.highlight.left = true
		matrix[ current_line ].logical.highlight.top = true
		if logical_volumes_quantity == 0 then
			matrix[ current_line ].logical.highlight.right = true
		else
			matrix[ current_line ].logical_volume.highlight.top = true
			matrix[ current_line ].logical_volume.highlight.right = true
		end

		for i = current_line, future_line - 1, physical_rowspan do
			matrix[ i ].physical.highlight.left = true
		end
		if logical_volumes_quantity ~= 0 then
			for i = current_line, future_line - 1, logical_volume_rowspan do
				matrix[ i ].logical_volume.highlight.right = true
			end
		end
		matrix[ future_line - physical_rowspan ].physical.highlight.bottom = true
		matrix[ current_line ].logical.highlight.bottom = true
		if logical_volumes_quantity ~= 0 then
			matrix[ future_line - logical_volume_rowspan ].logical_volume.highlight.bottom = true
		end

		current_line = future_line
	end

	for _, physical in pairs( einarc.Physical.sort( physicals_free ) ) do
		matrix[ current_line ] = { physical = physical }
		matrix[ current_line ].physical.rowspan = 1
		matrix[ current_line ].physical.highlight = common.deepcopy( highlights )
		current_line = current_line + 1
	end

	return matrix
end

function M.mib2tib( size )
	return string.sub( string.format( "%0.3f", size / 2^30 ), 1, -2 )
end

local function filter_mib2tib( matrix )
	for _, line in ipairs( matrix ) do
		if line.physical then
			line.physical.size = M.mib2tib( line.physical.size )
		end
		if line.logical then
			line.logical.capacity = M.mib2tib( line.logical.capacity )
		end
		if line.logical_volume then
			line.logical_volume.size = M.mib2tib( line.logical_volume.size )
		end
	end
	return matrix
end

local function device_lvms( device, physical_volumes )
	local physical_volumes = {}
	if not physical_volumes then
		physical_volumes = lvm.PhysicalVolume.list()
	end
	for _, physical_volume in ipairs( physical_volumes ) do
		if physical_volume.device == device then
			physical_volumes[ #physical_volumes + 1 ] = physical_volume
		end
	end
	return lvm.LogicalVolume.list( lvm.VolumeGroup.list( physical_volumes ) )
end

function M.caller()
	local logicals = einarc.Logical.list()
	local physical_volumes = lvm.PhysicalVolume.list()
	for logical_id, logical in pairs( logicals ) do
		logicals[ logical_id ]:physical_list()
		logicals[ logical_id ]:progress_get()
		logicals[ logical_id ].logical_volumes = device_lvms( logical.device, physical_volumes )
	end
	local matrix = M.overall( {
		physicals = einarc.Physical.list(),
		logicals = logicals
	} )
	local FILTERS = {
		filter_mib2tib
	}
	for _,filter in ipairs( FILTERS ) do
		matrix = filter( matrix )
	end
	return matrix
end

return M