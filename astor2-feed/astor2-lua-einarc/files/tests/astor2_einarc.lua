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
]]

require( "luaunit" )
common = require( "astor2.common" )
einarc = require( "astor2.einarc" )

TestIsId = {}
	function TestIsId:test_is_id()
		assertEquals( einarc.physical.is_id( "foo:bar" ), false )
		assertEquals( einarc.physical.is_id( "10:bar" ), false )
		assertEquals( einarc.physical.is_id( "10:20" ), true )
		assertEquals( einarc.physical.is_id( "10_20" ), false )
	end

TestSortPhysicals = {}
	function TestSortPhysicals:setUp()
		self.physical_list = {
			[ "0:4" ] = { model = "model1",
				      revision = "rev1",
				      serial = "serial1",
				      size = 100,
				      state = "free" },
			[ "2:2" ] = { model = "model2",
				      revision = "rev2",
				      serial = "serial2",
				      size = 200,
				      state = "0" },
			[ "1:3" ] = { model = "model3",
				      revision = "rev3",
				      serial = "serial3",
				      size = 300,
				      state = "free" },
			[ "0:1" ] = { model = "model4",
				      revision = "rev4",
				      serial = "serial4",
				      size = 400,
				      state = "0" },
			[ "10:5" ] = { model = "model5",
				       revision = "rev5",
				       serial = "serial5",
				       size = 500,
				       state = "hotspare" },
			[ "10:11" ] = { model = "model6",
				        revision = "rev6",
				        serial = "serial6",
				        size = 600,
				        state = "free" },
			[ "10:1" ] = { model = "model7",
				       revision = "rev7",
				       serial = "serial7",
				       size = 700,
				       state = "failed" } }

		self.ids_sort = { "0:1", "0:4", "1:3", "2:2", "10:1", "10:5", "10:11" }

		self.true_sorted_physical_list = {
			{ id = "0:1",
			  model = "model4",
			  revision = "rev4",
			  serial = "serial4",
			  size = 400,
			  state = "0" },
			{ id = "2:2",
			  model = "model2",
			  revision = "rev2",
			  serial = "serial2",
			  size = 200,
			  state = "0" },
			{ id = "10:1",
			  model = "model7",
			  revision = "rev7",
			  serial = "serial7",
			  size = 700,
			  state = "failed" },
			{ id = "0:4",
			  model = "model1",
			  revision = "rev1",
			  serial = "serial1",
			  size = 100,
			  state = "free" },
			{ id = "1:3",
			  model = "model3",
			  revision = "rev3",
			  serial = "serial3",
			  size = 300,
			  state = "free" },
			{ id = "10:11",
			  model = "model6",
			  revision = "rev6",
			  serial = "serial6",
			  size = 600,
			  state = "free" },
			{ id = "10:5",
			  model = "model5",
			  revision = "rev5",
			  serial = "serial5",
			  size = 500,
			  state = "hotspare" } }
	end

	function TestSortPhysicals:test_split_id()
		assertError( einarc.physical.split_id, "foobar" )
		assertError( einarc.physical.split_id, "foo:bar" )
		local left, right = einarc.physical.split_id( "0:1" )
		assertEquals( left, 0 )
		assertEquals( right, 1 )
	end

	function TestSortPhysicals:test_sort_ids()
		local ids = common.keys( self.physical_list )
		table.sort( ids, einarc.physical.sort_ids )
		assertEquals( common.compare_arrays( ids, self.ids_sort ), true )
	end

	function TestSortPhysicals:test_sort_state_list()
		assertEquals( true, common.compare_tables(
					einarc.physical.sorted_list( self.physical_list ),
					self.true_sorted_physical_list ) )
	end

LuaUnit:run()
