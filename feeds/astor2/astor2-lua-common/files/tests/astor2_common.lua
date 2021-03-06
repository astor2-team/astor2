--[[
  aStor2 -- storage area network configurable via Web-interface
  Copyright (C) 2009-2012 ETegro Technologies, PLC
                          Sergey Matveev <stargrave@stargrave.org>
                          Vladimir Petukhov <vladimir.petukhov@etegro.com>

  This program is free software: you can redistribute it and/or modify
  it under the terms of the GNU General Public License as published by
  the Free Software Foundation, either version 3 of the License, or
  (at your option) any later version.
  
  This program is distributed in the hope that it will be useful,
  but WITHOUT ANY WARRANTY; without even the implied warranty of
  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
  GNU General Public License for more details.
  
  You should have received a copy of the GNU General Public License
  along with this program.  If not, see <http://www.gnu.org/licenses/>.
]]

require( "luaunit" )
common = require( "astor2.common" )

TestIsInArray = {}
	function TestIsInArray:setUp()
		self.a = { "foo", "bar", "baz", 666, 13, 27 }
	end
	function TestIsInArray:test_number()
		assertError( common.is_in_array, self.a, 13 )
		assert( common.is_in_array( 13, self.a ) )
		assert( not common.is_in_array( 20, self.a ) )
	end
	function TestIsInArray:test_string()
		assert( common.is_in_array( "foo", self.a ) )
		assert( not common.is_in_array( "foobar", self.a ) )
	end

TestIsObj = {}
	function TestIsObj:test_number()
		assert( common.is_number( 13 ) )
		assert( not common.is_number( "foo" ) )
		assert( not common.is_number( {"foo"} ) )
	end
	function TestIsObj:test_string()
		assert( common.is_string( "foo" ) )
		assert( not common.is_string( 13 ) )
		assert( not common.is_string( {"foo"} ) )
	end
	function TestIsObj:test_table()
		assert( not common.is_table( "foo" ) )
		assert( not common.is_table( 13 ) )
		assert( common.is_table( {"foo"} ) )
	end
	function TestIsObj:test_odd()
		assertError( common.is_odd, "13" )
		assert( common.is_odd( 4 ) )
		assert( not common.is_odd( 5 ) )
	end
	function TestIsObj:test_positive()
		assertError( common.is_positive, "foo" )
		assert( common.is_positive( 100 ) )
		assert( common.is_positive( 1E12 ) )
		assert( not common.is_positive( -17 ) )
		assert( not common.is_positive( 0 ) )
		assert( not common.is_positive( -1E12 ) )
	end
	function TestIsObj:test_array()
		assert( common.is_array( { 1,2,3,4,5 } ) )
		assert( not common.is_array( { foo = "bar" } ) )
	end

TestStrip = {}
	function TestStrip:test_basic()
		assertEquals( common.strip( "foobar" ), "foobar" )
		assertEquals( common.strip( " foobar" ), "foobar" )
		assertEquals( common.strip( "foobar " ), "foobar" )
		assertEquals( common.strip( " foobar " ), "foobar" )
		assertEquals( common.strip( "     foobar    " ), "foobar" )
	end
	function TestStrip:test_spaces_inside()
		assertEquals( common.strip( "     foo   bar    " ), "foo   bar" )
	end
	function TestStrip:test_tabd()
		assertEquals( common.strip( "	foobar	" ), "foobar" )
	end
	function TestStrip:test_strip_single_character()
		assertEquals( common.strip( "B" ), "B" )
	end

TestGetKeys = {}
        function TestGetKeys:setUp()
		self.physical_list = {
			[ "0:4" ] = { size = 100, state = "free" },
			[ "2:2" ] = { size = 200, state = "0" },
			[ "1:3" ] = { size = 300, state = "free" },
			[ "0:1" ] = { size = 400, state = "0" },
			[ "10:5" ] = { size = 500, state = "hotspare" },
			[ "10:11" ] = { size = 600, state = "free" },
			[ "10:1" ] = { size = 700, state = "failed" } }

	end
	function TestGetKeys:test_keys()
		local keys_number = 0
		for _,_ in pairs( self.physical_list ) do
			keys_number = keys_number + 1
		end
		local ids_keys = common.keys( self.physical_list )
		assertEquals( #ids_keys, keys_number )
		for _,id in ipairs( ids_keys ) do
			assert( self.physical_list[id] ~= nil )
		end
	end

TestUniqueKeys = {}
        function TestUniqueKeys:setUp()
		self.hash = {
			["0:1"] = { state = "free", model = "erste" },
			["0:2"] = { state = "free", model = "zweite" },
			["0:3"] = { state = "free", model = "dritte" },
			["1:1"] = { state = "failed", model = "erste" },
			["1:2"] = { state = "failed", model = "zweite" },
			["1:3"] = { state = "failed", model = "dritte" }
		}
	end
	function TestUniqueKeys:test_by_state()
		local result = common.unique_keys( "state", self.hash )
		assertEquals( #common.keys( result ), 2 )
		assertEquals( #result["free"], 3 )
		assertEquals( #result["failed"], 3 )
		assert( common.is_in_array( "1:2", result["failed"] ) )
		assert( common.is_in_array( "1:3", result["failed"] ) )
		assert( not common.is_in_array( "0:3", result["failed"] ) )
	end
	function TestUniqueKeys:test_by_model()
		local result = common.unique_keys( "model", self.hash )
		assertEquals( #common.keys( result ), 3 )
		assertEquals( #result["erste"], 2 )
		assertEquals( #result["zweite"], 2 )
		assertEquals( #result["dritte"], 2 )
		assert( common.is_in_array( "1:2", result["zweite"] ) )
		assert( common.is_in_array( "1:3", result["dritte"] ) )
	end

TestSplitting = {}
	function TestSplitting:test_splitting_comma()
		assert( common.compare_tables( common.split_by( "foo,bar,baz", "," ), { "foo", "bar", "baz" } ) )
	end
	function TestSplitting:test_splitting_whitespace()
		assert( common.compare_tables( common.split_by( "foo bar   baz", " " ), { "foo", "bar", "baz" } ) )
	end
	function TestSplitting:test_character_splitting()
		assert( common.compare_tables( common.split_into_chars( "foo" ), { "f", "o", "o" } ) )
		assert( common.compare_tables( common.split_into_chars( "" ), { } ) )
	end

TestAttrSearching = {}
	function TestAttrSearching:test_single_attr_only_in_arr()
		assert( common.compare_tables( common.search_attr( {
			{ foo = "bar" },
			{ bar = "baz" },
			{ neededone = "foo" }
		}, "neededone" ), {
			{ neededone = "foo" }
		} ) )
	end
	function TestAttrSearching:test_single_attr_only_in_table()
		assert( common.compare_tables( common.search_attr( {
			foo = { foo = "bar" },
			bar = { bar = "baz" },
			baz = { neededone = "foo" }
		}, "neededone" ), {
			{ neededone = "foo" }
		} ) )
	end
	function TestAttrSearching:test_single_attr_in_table()
		assert( common.compare_tables( common.search_attr( {
			foo = { foo = "bar" },
			bar = { bar = "baz" },
			baz = { neededone = "foo" }
		}, "neededone", "needthis" ), { } ) )
		assert( common.compare_tables( common.search_attr( {
			foo = { foo = "bar" },
			bar = { bar = "baz" },
			baz = { neededone = "needthis" }
		}, "neededone", "needthis" ), {
			{ neededone = "needthis" }
		} ) )
	end
	function TestAttrSearching:test_several_attr_in_arr()
		assert( common.compare_tables( common.search_attr( {
			{ foo = "bar" },
			{ bar = "baz" },
			{ neededone = "needthis" },
			{ neededone = "needthis", triv = "foo" }
		}, "neededone", "needthis" ), {
			{ neededone = "needthis" },
			{ neededone = "needthis", triv = "foo" }
		} ) )
	end

TestFileExistence = {}
	function TestFileExistence:test_existent()
		assert( common.file_exists( "tests/astor2_common.lua" ) == true )
	end
	function TestFileExistence:test_nonexistent()
		assert( common.file_exists( "tests/non_existent" ) == false )
	end
	function TestFileExistence:test_non_readable()
		local tmp = os.tmpname()
		os.execute( "touch " .. tmp )
		os.execute( "chmod 000 " .. tmp )
		local return_value = common.file_exists( tmp )
		os.execute( "rm -f " .. tmp )
		assert( return_value == nil )
	end

TestTableComparing = {}
	function TestTableComparing:setUp()
		self.table = {
			foo = { "foo", "bar", "baz" },
			bar = { 1,2,3,4,5 },
			baz = "foobar",
			foobar = 666,
			foobaz = { some = "value", another = "value2" }
		}
	end
	function TestTableComparing:test_deepcopy()
		local copied = common.deepcopy( self.table )
		assert( common.is_table( copied ) )
		assert( common.is_array( copied["foo"] ) )
		assertEquals( #copied["foo"], 3 )
		assertEquals( copied["foo"][1], "foo" )
		assertEquals( copied["foo"][2], "bar" )
		assertEquals( copied["foo"][3], "baz" )
		assert( common.is_array( copied["bar"] ) )
		assertEquals( #copied["bar"], 5 )
		assertEquals( copied["bar"][1], 1 )
		assertEquals( copied["bar"][2], 2 )
		assertEquals( copied["bar"][3], 3 )
		assertEquals( copied["bar"][4], 4 )
		assertEquals( copied["bar"][5], 5 )
		assert( common.is_string( copied["baz"] ) )
		assertEquals( copied["baz"], "foobar" )
		assert( common.is_number( copied["foobar"] ) )
		assertEquals( copied["foobar"], 666 )
		assert( common.is_table( copied["foobaz"] ) )
		assertEquals( copied["foobaz"]["some"], "value" )
		assertEquals( copied["foobaz"]["another"], "value2" )
	end
	function TestTableComparing:test_compare_equal()
		local copied = self.table
		assertEquals( copied, self.table )
		assert( common.compare_tables( self.table, copied ) == true )
	end
	function TestTableComparing:test_compare_equal_modified()
		local copied = self.table
		copied["foobar"] = 123
		assertEquals( copied, self.table )
		assert( common.compare_tables( self.table, copied ) == true )
	end
	function TestTableComparing:test_compare_array()
		assertEquals( common.compare_tables( {1,2,3}, {1,2,3} ), true )
		assertEquals( common.compare_tables( {"foo","bar"}, {"foo","bar"} ), true )
		local a1 = { "foo", "bar" }
		local a2 = common.deepcopy( a1 )
		assertEquals( common.compare_tables( a1, a2 ), true )
		a2[3] = "baz"
		assertEquals( common.compare_tables( a1, a2 ), false )
	end
	function TestTableComparing:test_compare_hash_with_arrays()
		local t1 = { foo = { 1,2,3 }, bar = "baz" }
		local t2 = common.deepcopy( t1 )
		assertEquals( common.compare_tables( t1, t2 ), true )
		t2["baz"] = "foo"
		assertEquals( common.compare_tables( t1, t2 ), false )
	end

	function TestTableComparing:test_compare()
		local copied = common.deepcopy( self.table )
		assert( self.table ~= copied )
		assertEquals( common.compare_tables( self.table, copied ), true )
	end
	function TestTableComparing:test_compare_modified()
		local copied = common.deepcopy( self.table )
		assert( self.table ~= copied )
		assertEquals( common.compare_tables( self.table, copied ), true )
		copied["foobar"] = 123
		assertEquals( common.compare_tables( self.table, copied ), false )
	end

LuaUnit:run()
