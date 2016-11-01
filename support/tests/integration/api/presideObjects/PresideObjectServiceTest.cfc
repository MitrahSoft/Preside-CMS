<cfcomponent output="false" extends="tests.resources.HelperObjects.PresideTestCase">

	<cffunction name="setup" access="public" returntype="void" output="false">
		<cfscript>
			super.setup();
			_dropAllTables();
		</cfscript>
	</cffunction>

<!--- tests --->
	<cffunction name="test001_dbSync_shouldCreateComponentTables" returntype="void">
		<cfscript>
			var poService = _getService( objectDirectories=[ "/tests/resources/PresideObjectService/basicEmptyComponents/" ] );
			var tables    = "";
			var i         = "";
			var columns   = "";

			poService.dbSync();
			tables = _getDbTables();

			super.assertEquals( 6, ListLen( tables ), "Expecting 5 tables to have been created. In fact, there are #ListLen( tables ) - 1#" );
			for( i=1; i lte 5; i++ ) {
				super.assert( ListFind( tables, "ptest_object_#i#" ), "Table for object_#i# was not created." );
				columns = _getDbTableColumns( "ptest_object_#i#" );

				super.assert( StructKeyExists( columns, "id" ), "The id column was not created." );
				super.assertEquals( "varchar", columns.id.type_name, "The id column was not a varchar." );
				super.assertEquals( "35", columns.id.column_size, "The id column did not have a length of 35." );
				super.assertFalse( columns.id.nullable, "The id column should not be nullable" );
				super.assert( columns.id.is_primarykey, "The id column should be the primary key" );

				super.assert( StructKeyExists( columns, "label" ), "The label column was not created." );
				super.assertEquals( "varchar", columns.label.type_name, "The label column was not a varchar." );
				super.assertEquals( "250", columns.label.column_size, "The label column did not have a length of 250." );
				super.assertFalse( columns.label.nullable, "The label column should not be nullable" );

				super.assert( StructKeyExists( columns, "datecreated" ), "The datecreated column was not created." );
				super.assertEquals( "datetime", columns.datecreated.type_name, "The datecreated column was not a datetime field." );
				super.assertFalse( columns.datecreated.nullable, "The datecreated column should not be nullable" );
				super.assert( StructKeyExists( columns, "datemodified" ), "The datemodified column was not created." );
				super.assertEquals( "datetime", columns.datemodified.type_name, "The datemodified column was not a datetime field." );
				super.assertFalse( columns.datemodified.nullable, "The datemodified column should not be nullable" );
			}
		</cfscript>
	</cffunction>

	<cffunction name="test002_dbSync_shouldNotCreateTables_whenTheyAlreadyExist" returntype="void">
		<cfscript>
			var poService = _getService( objectDirectories=[ "/tests/resources/PresideObjectService/basicEmptyComponents/" ] );
			var tables    = "";
			var i         = "";
			var columns   = "";

			poService.dbSync();
			tables = _getDbTables();
			super.assertEquals( 6, ListLen( tables ), "Expecting 5 tables to have been created. In fact, there are #ListLen( tables )-1#" );

			poService.dbSync(); // if the code was trying to recreate them here, there would be an error (could do with a more stringent test here)

			tables = _getDbTables();
			super.assertEquals( 6, ListLen( tables ), "Expecting 5 tables to have been created. In fact, there are #ListLen( tables )-1#" );
		</cfscript>
	</cffunction>

	<cffunction name="test003_dbSync_shouldCreateVariousKindsOfColumnsAndWorkWithInheritance" returntype="void">
		<cfscript>
			var poService      = _getService( objectDirectories=[ "/tests/resources/PresideObjectService/componentsWithSomeInheritanceAndMoreFields/" ] );
			var tables         = "";
			var i              = "";
			var columns        = "";
			var expectedTables = [ "test_test_1", "test_test_2", "test_3" ];
			var table          = "";

			poService.dbSync();
			tables = _getDbTables();

			super.assertEquals( ArrayLen( expectedTables ) + 1, ListLen( tables ), "Expected #ArrayLen( expectedTables )# tables to be created. Got #ListLen( tables ) - 1#" );
			for( table in expectedTables ){
				super.assert( ListFindNoCase( tables, table ), "The table, '#table#', was not created." );
				columns = _getDbTableColumns( table );

				super.assert( StructKeyExists( columns, "id" ), "The id column was not created." );
				super.assertEquals( "int", columns.id.type_name, "The id column was not an int." );
				super.assertFalse( columns.id.nullable, "The id column should not be nullable" );
				super.assert( columns.id.is_primarykey, "The id column should be the primary key" );
				super.assert( columns.id.is_autoincrement, "The id column should be auto incrementing" );

				super.assert( StructKeyExists( columns, "test_property" ), "The test_property column was not created." );
				super.assertEquals( "bit", columns.test_property.type_name, "The test_property column was not an bit." );

				switch( table ){
					case "test_test_1":
						super.assert( columns.test_property.nullable, "The test_property column for table 1 was not nullable." );
					break;
					case "test_test_2":
					case "test_3":
						super.assert( columns.test_property.nullable, "The test_property column for table 1 was not nullable." );

						super.assert( StructKeyExists( columns, "some_date" ), "The some_date column was not created." );
						super.assertEquals( "datetime", columns.some_date.type_name, "The some_date column was not an int." );

						if ( table eq "test_table_2" ){
							super.assertFalse( columns.some_date.nullable, "The some_date column for table 2 was nullable." );

						} else {
							// RAILO is RETURNING THAT THIS COLUMN IS NOT NULLABLE WHEN IN FACT IT IS IN THE DB :s, NOT RUNNING TEST
							// super.assert( columns.some_date.nullable, "The some_date column for table 3 was not nullable." );
						}
					break;
				}
			}
		</cfscript>
	</cffunction>

	<cffunction name="test004_dbSync_shouldModifyTables_whenComponentFieldsChange" returntype="void">
		<cfscript>
			var poService      = _getService( objectDirectories=[ "/tests/resources/PresideObjectService/componentsWithSomeInheritanceAndMoreFields/" ] );
			var tables         = "";
			var i              = "";
			var columns        = "";
			var expectedTables = [ "test_test_1", "test_test_2", "test_3" ];
			var table          = "";

			poService.dbSync();

			// load new component definitions (cheating by using a different folder)
			poService = _getService( objectDirectories=[ "/tests/resources/PresideObjectService/componentsWithSomeInheritanceAndMoreFields_changed/" ] );
			try {
				poService.dbSync();

			} catch ( any e ) {
				super.fail( "DB Sync failed. Error: " & SerializeJson( e ) );
			}

			tables = _getDbTables();

			super.assertEquals( ArrayLen( expectedTables ) + 1, ListLen( tables ), "Expected #ArrayLen( expectedTables )# tables to be created. Got #ListLen( tables ) - 1#" );

			for( table in expectedTables ){
				super.assert( ListFindNoCase( tables, table ), "The table, '#table#', was not created." );
				columns = _getDbTableColumns( table );

				super.assert( StructKeyExists( columns, "id" ), "The id column was not created." );
				super.assertEquals( "varchar", columns.id.type_name, "The id column was not a varchar." );
				super.assertEquals( "35", columns.id.column_size, "The id column did not have a length of 35." );
				super.assertFalse( columns.id.nullable, "The id column should not be nullable" );
				super.assert( columns.id.is_primarykey, "The id column should be the primary key" );
				super.assertFalse( columns.id.is_autoincrement, "The id column should not be auto incrementing" );

				switch( table ){
					case "test_test_1":
						super.assert( StructKeyExists( columns, "__deprecated__test_property" ), "The test_property column was not soft deleted." );
						super.assertEquals( "bit", columns.__deprecated__test_property.type_name, "The test_property column was not a bit." );
						super.assert( columns.__deprecated__test_property.nullable, "The test_property column for table 1 was not nullable." );
					break;
					case "test_test_2":
					case "test_3":
						super.assert( StructKeyExists( columns, "test_property" ), "The test_property column does not exist." );
						super.assertEquals( "bit", columns.test_property.type_name, "The test_property column was not a bit." );
						super.assert( columns.test_property.nullable, "The test_property column for table 1 was not nullable." );

						super.assert( StructKeyExists( columns, "some_date" ), "The some_date column was not created." );
						super.assertEquals( "varchar", columns.some_date.type_name, "The some_date column was not changed to a text field." );

						if ( table eq "test_test_2" ){
							super.assertFalse( columns.some_date.nullable, "The some_date column for table 2 was nullable." );

						} else {
							super.assert( columns.some_date.nullable, "The some_date column for table 3 was not nullable." );
							super.assert( StructKeyExists( columns, "a_new_column" ), "The a_new_column column does not exist." );
							super.assertEquals( 200, columns.a_new_column.column_size, "The column size of the varchar field was not automatically set to 200." );
						}
					break;
				}
			}
		</cfscript>
	</cffunction>

	<cffunction name="test005_objectExists_shouldReturnFalse_whenObjectDoesNotExist" returntype="void">
		<cfscript>
			var poService = _getService( objectDirectories=[ "/tests/resources/PresideObjectService/componentsWithSomeInheritanceAndMoreFields/" ] );

			super.assertFalse( poService.objectExists( 'nonexistent_component' ), "Exists returned true for a non-existant component" );
		</cfscript>
	</cffunction>

	<cffunction name="test006_objectExists_shouldReturnTrue_whenObjectDoesExist" returntype="void">
		<cfscript>
			var poService = _getService( objectDirectories=[ "/tests/resources/PresideObjectService/componentsWithSomeInheritanceAndMoreFields/" ] );

			super.assert( poService.objectExists( 'object_1' ), "Exists returned false when the object exists (object_1)" );
			super.assert( poService.objectExists( 'object_2' ), "Exists returned false when the object exists (object_2)" );
			super.assert( poService.objectExists( 'object_3' ), "Exists returned false when the object exists (object_3)" );
		</cfscript>
	</cffunction>

	<cffunction name="test007_getObject_shouldReturnInstanceOfSpecifiedObject" returntype="void">
		<cfscript>
			var poService = _getService( objectDirectories=[ "/tests/resources/PresideObjectService/componentsWithSomeInheritanceAndMoreFields/" ] );
			var result    = poService.getObject( objectName="object_2" );

			super.assertEquals( "tests.resources.PresideObjectService.componentsWithSomeInheritanceAndMoreFields.object_2", GetMetaData( result ).name );
		</cfscript>
	</cffunction>

	<cffunction name="test007_1_getObject_shouldReturnInstanceOfSpecifiedObject_decoratedWithPresideObjectServiceMethods" returntype="void">
		<cfscript>
			var poService = _getService( objectDirectories=[ "/tests/resources/PresideObjectService/componentsWithSomeInheritanceAndMoreFields/" ] );
			var result    = poService.getObject( objectName="object_2" );
			var createdId = "";
			var record    = "";

			poService.dbSync();

			super.assertEquals( "preside_test_suite", result.getDsn() );
			super.assert( result.fieldExists( "id" ) );
			super.assertFalse( result.fieldExists( "non_existant_field" ) );

			createdId = result.insertData( { some_date="2013-08-01", label="test" } );
			super.assert( createdId );
			super.assert( result.updateData( data={ some_date="1990-01-01", label="testagain" }, filter={ id = createdId } ) );

			record = result.selectData( filter={ id = createdId } );
			super.assert( record.recordCount );
			super.assertEquals( "{ts '1990-01-01 00:00:00'}", record.some_date );
			super.assertEquals( "testagain", record.label );
		</cfscript>
	</cffunction>

	<cffunction name="test008_getObject_shouldThrowAppropriateError_whenObjectDoesNotExist" returntype="void">
		<cfscript>
			var poService   = _getService( objectDirectories=[ "/tests/resources/PresideObjectService/componentsWithSomeInheritanceAndMoreFields/" ] );
			var errorThrown = false;

			try {
				poService.getObject( objectName="some_object_that_does_not_exist" );
			} catch ( "PresideObjectService.missingObject" e ) {
				super.assertEquals( "Object [some_object_that_does_not_exist] does not exist", e.message );

				errorThrown = true;
			}

			super.assert( errorThrown, "An appropriate error was not thrown" );
		</cfscript>
	</cffunction>

	<cffunction name="test009_dbSync_shouldCreateIndexesAndUniqueIndexes" returntype="void">
		<cfscript>
			var poService = _getService( objectDirectories=[ "/tests/resources/PresideObjectService/componentWithIndexes/" ] );
			var expectedIndexes = {
				  ix_an_object_indexa     = { unique="false", fields="field1,field2,field5" }
				, ix_an_object_indexb     = { unique="false", fields="field6,field3"        }
				, ix_an_object_indexc     = { unique="false", fields="field4,field1"        }
				, ux_an_object_uniqueness = { unique="true" , fields="field2,field1"        }
				, ux_an_object_uniq       = { unique="true" , fields="field3"               }
			};
			var realIndexes = "";

			poService.dbSync();

			realIndexes = _getDbTableIndexes( "ptest_an_object" );

			super.assertEquals( expectedIndexes, realIndexes );

		</cfscript>

	</cffunction>

	<cffunction name="test010_dbSync_shouldAlterIndexesWhenTheyHaveChanged" returntype="void">
		<cfscript>
			var poService = _getService( objectDirectories=[ "/tests/resources/PresideObjectService/componentWithIndexes/" ] );
			var expectedIndexes = {
				  ix_an_object_indexa     = { unique="false", fields="field1,field2,field5" }
				, ix_an_object_indexb     = { unique="false", fields="field3,field6"        }
				, ix_an_object_indexc     = { unique="false", fields="field4,field1"        }
				, ix_an_object_indexd     = { unique="false", fields="field2"               }
				, ux_an_object_uniqueness = { unique="true" , fields="field4"               }
				, ux_an_object_uniq       = { unique="true" , fields="field3"               }
			};
			var realIndexes = "";

			poService.dbSync();

			poService = _getService( objectDirectories=[ "/tests/resources/PresideObjectService/componentWithIndexes_changed/" ] );

			poService.dbSync();

			realIndexes = _getDbTableIndexes( "ptest_an_object" );

			super.assertEquals( expectedIndexes, realIndexes );
		</cfscript>
	</cffunction>

	<cffunction name="test011_dbSync_shouldCreateForeignKeyConstraints_forOneToManyPropertyRelationships" returntype="void">
		<cfscript>
			var poService = _getService( objectDirectories=[ "/tests/resources/PresideObjectService/componentsWithRelationship/" ] );
			var constraints = "";
			var expectedResult = {
				"fk_c3f5fa6fe828a7c89f411d93d5e0ce7c" = {
					  pk_table  = "ptest_object_a"
					, fk_table  = "ptest_object_b"
					, pk_column = "id"
					, fk_column = "related_to_a"
					, on_update = "cascade"
					, on_delete = "error"
				},
				"fk_6a2b9624ca18e99fd0b48df47187ed70" = {
					  pk_table  = "ptest_object_a"
					, fk_table  = "ptest_object_b"
					, pk_column = "id"
					, fk_column = "related_to_a_again"
					, on_update = "cascade"
					, on_delete = "set null"
				},
				"fk_e8ad2c420c66dc63e413e0b99e7137e5" = {
					  pk_table  = "ptest_object_b"
					, fk_table  = "ptest_object_c"
					, pk_column = "id"
					, fk_column = "object_b"
					, on_update = "cascade"
					, on_delete = "error"
				}
			};
			var keys = "";

			poService.dbSync();

			keys = _getTableForeignKeys( "ptest_object_a" );
			StructAppend( keys, _getTableForeignKeys( "ptest_object_b" ) );
			StructAppend( keys, _getTableForeignKeys( "ptest_object_c" ) );

			super.assertEquals( expectedResult, keys );
		</cfscript>
	</cffunction>

	<cffunction name="test012_dbSync_shouldMakeForeignKeyChanges_whenRelationshipsChangeInComponents" returntype="void">
		<cfscript>
			var poService = _getService( objectDirectories=[ "/tests/resources/PresideObjectService/componentsWithRelationship/" ] );
			var constraints = "";
			var expectedResult = {
				"fk_7b0efa45ba5b99ef2e95c33daa364812" = {
					  pk_table  = "ptest_object_a"
					, fk_table  = "ptest_object_b"
					, pk_column = "id"
					, fk_column = "related_to_a"
					, on_update = "cascade"
					, on_delete = "set null"
				},
				"fk_fe1fa86e7f112dd7c84afaeeac1da997" = {
					  pk_table  = "ptest_object_a"
					, fk_table  = "ptest_object_c"
					, pk_column = "id"
					, fk_column = "object_b"
					, on_update = "cascade"
					, on_delete = "error"
				}
			};
			var keys = "";

			poService.dbSync();
			poService = _getService( objectDirectories=[ "/tests/resources/PresideObjectService/componentsWithRelationship_changed/" ] );
			poService.dbSync();

			keys = _getTableForeignKeys( "ptest_object_a" );
			StructAppend( keys, _getTableForeignKeys( "ptest_object_b" ) );
			StructAppend( keys, _getTableForeignKeys( "ptest_object_c" ) );

			super.assertEquals( expectedResult, keys );
		</cfscript>
	</cffunction>

	<cffunction name="test013_dbSync_shouldAutomaticallyCreatePivotTables_forManyToManyRelationships" returntype="void">
		<cfscript>
			var poService = _getService( objectDirectories=[ "/tests/resources/PresideObjectService/componentsWithManyToManyRelationship/" ] );
			var tables    = "";
			var i         = "";
			var columns   = "";

			poService.dbSync();
			tables = _getDbTables();

			super.assertEquals( 4, ListLen( tables ), "Expecting 3 tables to have been created. In fact, there are #ListLen( tables ) - 1#" );

			super.assert( ListFindNoCase( tables, "ptest_obj_a__join__obj_b" ), "Join table was not automatically created" );
		</cfscript>
	</cffunction>

	<cffunction name="test014_loadObjects_shouldThrowInformativeError_whenRelatedObjectRefersToAnObjectThatDoesNotExist" returntype="void">
		<cfscript>
			var poService       = "";
			var errorThrown     = false;
			var expectedMessage = "Object, [non_existant_object], could not be found";
			var expectedDetail  = "The property, [non_existant_object], in Preside component, [bad_object], declared a [many-to-one] relationship with the object [non_existant_object]; this object could not be found.";

			try {
				_getService( objectDirectories=[ "/tests/resources/PresideObjectService/componentWithBadRelationship/" ] );
			} catch ( "RelationshipGuidance.BadRelationship" e ) {
				super.assertEquals( expectedMessage, e.message );
				super.assertEquals( expectedDetail , e.detail );
				errorThrown = true;
			}

			super.assert( errorThrown, "A controlled error was not thrown" );
		</cfscript>
	</cffunction>

	<cffunction name="test015_dataExists_shouldReturnFalse_whenNoArgumentsPassedAndNoRecordsExist_andTrue_whenRecordsDoExist" returntype="void">
		<cfscript>
			var poService = _getService( objectDirectories=[ "/tests/resources/PresideObjectService/componentsWithRelationship/" ] );
			var q = new query();

			poService.dbSync();

			super.assertFalse( poService.dataExists( objectName="object_a" ), "dataExists() returned true when no data does exist" );

			q.setDatasource( application.dsn );
			q.setSQL( "insert into ptest_object_a ( label, datemodified, datecreated) values ('test', Now(), Now() )" );
			q.execute();

			cachebox.clearAll();

			super.assert( poService.dataExists( objectName="object_a" ), "dataExists() returned false when, in fact, data does exist!" );
		</cfscript>
	</cffunction>

	<cffunction name="test015_1_dataExists_shouldWorkWithPlainTextSqlFilter" returntype="void">
		<cfscript>
			var poService = _getService( objectDirectories=[ "/tests/resources/PresideObjectService/componentsWithRelationship/" ] );
			var q = new query();
			var result = "";
			var filter = "label like :label and ( DateDiff( Now(), datemodified ) <= :age or DateDiff( Now(), datecreated ) <= :age )";
			var filterParams = {
				  label = "test%"
				, age       = { value=2, type="cf_sql_integer" }
			};

			poService.dbSync();

			result = poService.dataExists(
				  objectName   = "object_a"
				, filter       = filter
				, filterParams = filterParams
			);

			super.assertFalse( result, "dataExists() returned true when no data does exist" );

			q.setDatasource( application.dsn );
			q.setSQL( "insert into ptest_object_a ( label, datemodified, datecreated) values ('test', Now(), Now() )" );
			q.execute();

			result = poService.dataExists(
				  objectName   = "object_a"
				, filter       = filter
				, filterParams = filterParams
			);

			super.assert( result, "dataExists() returned false when, in fact, data does exist!" );
		</cfscript>
	</cffunction>

	<cffunction name="test015_2_dataExists_shouldWorkWithPlainTextSqlFilterAndAutoMagicJoins" returntype="void">
		<cfscript>
			var poService = _getService( objectDirectories=[ "/tests/resources/PresideObjectService/componentsWithAutoJoinableRelationships/" ] );
			var q = new query();
			var result = "";
			var filter = "object_e.label like :object_e.label and ( DateDiff( Now(), object_e.datemodified ) <= :age or DateDiff( Now(), object_d.datecreated ) <= :age )";
			var filterParams = {
				  "object_e.label" = "test%"
				, age       = { value=2, type="cf_sql_integer" }
			};
			var eId = "";

			poService.dbSync();

			result = poService.dataExists(
				  objectName   = "object_d"
				, filter       = filter
				, filterParams = filterParams
			);

			super.assertFalse( result, "dataExists() returned true when no data does exist" );

			eId = poService.insertData( objectName="object_e", data={ label="test data" } );
			eId = poService.insertData( objectName="object_d", data={ label="isn't this lovely", object_e=eId } );

			result = poService.dataExists(
				  objectName   = "object_d"
				, filter       = filter
				, filterParams = filterParams
			);

			super.assert( result, "dataExists() returned false when, in fact, data does exist!" );
		</cfscript>
	</cffunction>

	<cffunction name="test016_dataExists_shouldReturnFalse_whenNoDataMatchesTheSimpleFilter_andTrue_whenRecordsDoMatch" returntype="void">
		<cfscript>
			var poService = _getService( objectDirectories=[ "/tests/resources/PresideObjectService/componentsWithRelationship/" ] );
			var result    = "";
			var q = new query();

			poService.dbSync();

			q.setDatasource( application.dsn );
			q.setSQL( "insert into ptest_object_a ( label, datemodified, datecreated) values ('test', Now(), Now() )" );
			q.execute();

			result = poService.dataExists(
				  objectName = "object_a"
				, filter     = { label = "test", id = 1 }
			);
			super.assert( result, "dataExists() returned false when data should exist that matches the basic filter" );


			result = poService.dataExists(
				  objectName   = "object_a"
				, filter     = { label = "i do not exist", id = 1 }
			);
			super.assertFalse( result, "dataExists() returned true when no data should exist that matches the basic filter" );

			result = poService.dataExists(
				  objectName   = "object_a"
				, filter     = { label = "test", id = 1321 }
			);
			super.assertFalse( result, "dataExists() returned true when no data should exist that matches the basic filter" );
		</cfscript>
	</cffunction>

	<cffunction name="test017_dataExists_shouldAllowMagicFilteringAcrossRelationships" returntype="void">
		<cfscript>
			var poService = _getService( objectDirectories=[ "/tests/resources/PresideObjectService/componentsWithAutoJoinableRelationships/" ] );
			var result    = "";
			var q = new query();
			var eId = CreateUUId();
			var bId = CreateUUId();
			var cId = CreateUUId();
			var fId = CreateUUId();

			poService.dbSync();

			q.setDatasource( application.dsn );
			q.setSQL( "insert into ptest_object_a ( datecreated, datemodified, label ) values (  Now(), Now(), 'a test' )" );
			q.execute();

			q = new query();
			q.setDatasource( application.dsn );
			q.setSQL( "insert into ptest_object_e ( datecreated, datemodified, id, label ) values (  Now(), Now(), '#eId#','e test' )" );
			q.execute();

			q = new query();
			q.setDatasource( application.dsn );
			q.setSQL( "insert into ptest_object_d ( datecreated, datemodified, label, object_e ) values (  Now(), Now(), 'd test', '#eId#' )" );
			q.execute();

			q = new query();
			q.setDatasource( application.dsn );
			q.setSQL( "insert into ptest_object_b ( datecreated, datemodified, id, label, related_to_a, object_d ) values (  Now(), Now(),  '#bId#', 'b test', 1, 1 )" );
			q.execute();

			q = new query();
			q.setDatasource( application.dsn );
			q.setSQL( "insert into ptest_object_c ( datecreated, datemodified, id, label, object_b ) values (  Now(), Now(),  '#cId#', 'testing c', '#bId#' )" );
			q.execute();

			q = new query();
			q.setDatasource( application.dsn );
			q.setSQL( "insert into ptest_object_f ( datecreated, datemodified, id, label, object_c ) values (  Now(), Now(),  '#fId#', 'testing f', '#cId#' )" );
			q.execute();

			result = poService.dataExists(
				  objectName = "object_a"
				, filter     = { "object_f.label" = "testing f" , "object_e.id" = eId }
			);
			super.assert( result, "dataExists() returned false when data should exist that matches the basic filter" );

			result = poService.dataExists(
			 	  objectName   = "object_a"
			 	, filter     = { "object_f.label" = "testing f" , "object_e.id" = "not correct" }
			);
			super.assertFalse( result, "dataExists() returned true when no data should exist that matches the basic filter" );

			result = poService.dataExists(
				  objectName = "object_a"
				, filter     = { "object_f.label" = "not exists" , "object_e.id" = eId }
			);
			super.assertFalse( result, "dataExists() returned true when no data should exist that matches the basic filter" );
		</cfscript>
	</cffunction>

	<cffunction name="test018_deleteData_shouldDeleteDataWithBasicFilter" returntype="void">
		<cfscript>
			var poService = _getService( objectDirectories=[ "/tests/resources/PresideObjectService/componentsWithRelationship/" ] );
			var result    = "";
			var q = new query();

			poService.dbSync();

			q.setDatasource( application.dsn );
			q.setSQL( "insert into ptest_object_a ( label, datemodified, datecreated) values ('test', Now(), Now() )" );
			q.execute();

			result = poService.deleteData(
				  objectName = "object_a"
				, filter     = { label = "test", id = 1 }
			);
			super.assertEquals( 1, result, "Expected deleteData() to return 1 as the number of records deleted" );

			q.setDatasource( application.dsn );
			q.setSQL( "select * from ptest_object_a where id = 1" );
			result = q.execute();

			super.assertEquals( 0, result.getResult().recordCount, "The row was not physically deleted." );
		</cfscript>
	</cffunction>

	<cffunction name="test018_1_deleteData_shouldDeleteDataWithBasicINFilter" returntype="void">
		<cfscript>
			var poService = _getService( objectDirectories=[ "/tests/resources/PresideObjectService/componentsWithRelationship/" ] );
			var result    = "";
			var q = new query();

			poService.dbSync();

			q.setDatasource( application.dsn );
			q.setSQL( "insert into ptest_object_a ( datecreated, datemodified, label ) values ( Now(), Now(), 'test'),( Now(), Now(), 'test2'),( Now(), Now(), 'test3'),( Now(), Now(), 'test4')" );
			q.execute();

			result = poService.deleteData(
				  objectName = "object_a"
				, filter     = { id = [1,3,4,5,6] }
			);
			super.assertEquals( 3, result, "Expected deleteData() to return 3 as the number of records deleted" );

			q.setDatasource( application.dsn );
			q.setSQL( "select * from ptest_object_a where id in (1,3,4)" );
			result = q.execute();

			super.assertEquals( 0, result.getResult().recordCount, "The rows were not physically deleted." );
		</cfscript>
	</cffunction>

	<cffunction name="test018_2_deleteData_shouldDeleteDataWithBasicPlainTextFilter" returntype="void">
		<cfscript>
			var poService = _getService( objectDirectories=[ "/tests/resources/PresideObjectService/componentsWithRelationship/" ] );
			var result    = "";
			var q = new query();

			poService.dbSync();

			q.setDatasource( application.dsn );
			q.setSQL( "insert into ptest_object_a ( datecreated, datemodified, label ) values ( Now(), Now(), 'test'),( Now(), Now(), 'test2'),( Now(), Now(), 'test3'),( Now(), Now(), 'test4')" );
			q.execute();

			result = poService.deleteData(
				  objectName = "object_a"
				, filter     = "id = :id and label like :label"
				, filterParams = { id = 2, label = "test%" }
			);
			super.assertEquals( 1, result, "Expected deleteData() to return 1 as the number of records deleted" );

			q.setDatasource( application.dsn );
			q.setSQL( "select * from ptest_object_a where id = 2" );
			result = q.execute();

			super.assertEquals( 0, result.getResult().recordCount, "The rows were not physically deleted." );
		</cfscript>
	</cffunction>

	<cffunction name="test019_deleteData_shouldThrowInformativeError_whenNoFilterSuppliedAndForceDeleteAllNotSetToTrue" returntype="void">
		<cfscript>
			var poService = _getService( objectDirectories=[ "/tests/resources/PresideObjectService/componentsWithRelationship/" ] );
			var errorThrown = false;

			poService.dbSync();

			try {
				poService.deleteData( objectName = "object_b" );
			} catch( "PresideObjects.deleteAllProtection" e ) {
				super.assertEquals( "A call to delete records in [object_b] was made without any filter which would lead to all records being deleted", e.message );
				super.assertEquals( "If you wish to delete all records, you must set the [forceDeleteAll] argument of the [deleteData] method to true", e.detail );
				errorThrown = true;
			}

			super.assert( errorThrown, "No informative error was thrown" );
		</cfscript>
	</cffunction>

	<cffunction name="test020_deleteData_shouldDeleteAllRecords_whenNoFilterSupplied_andWhenForceDeleteAllIsSetToTrue" returntype="void">
		<cfscript>
			var poService = _getService( objectDirectories=[ "/tests/resources/PresideObjectService/componentsWithRelationship/" ] );
			var result    = "";
			var q = new query();

			poService.dbSync();

			q.setDatasource( application.dsn );
			q.setSQL( "insert into ptest_object_a ( label, datemodified, datecreated) values ('test', Now(), Now() ), ('test2', Now(), Now() ), ('test3', Now(), Now() ), ('test4', Now(), Now() )" );
			q.execute();

			super.assert( poService.dataExists( objectName="object_a" ), "Test failed, data should have been inserted into the table before attempting the delete" );

			result = poService.deleteData(
				  objectName     = "object_a"
				, forceDeleteAll = true
			);
			super.assertEquals( 4, result, "Expected deleteData() to return 4 as the number of records deleted" );

			q.setDatasource( application.dsn );
			q.setSQL( "select * from ptest_object_a" );
			result = q.execute();

			super.assertEquals( 0, result.getResult().recordCount, "Expected no records to exist. Instead, discovered that there are #result.getResult().recordCount# records" );
		</cfscript>
	</cffunction>

	<cffunction name="test021_insertData_shouldInsertDataAndReturnNewlyCreateId_whenObjIdIsAutoIncrementingNumeric" returntype="void">
		<cfscript>
			var poService = _getService( objectDirectories=[ "/tests/resources/PresideObjectService/componentsWithRelationship/" ] );
			var result    = "";
			var newId = "";

			poService.dbSync();

			newId = poService.insertData( objectName="object_a", data={
				label = "This is a test"
			} );

			super.assertEquals( 1, newId );

			super.assert( poService.dataExists( objectname="object_a", filter={ id=1, label="This is a test" } ), "Record was not created" );
		</cfscript>
	</cffunction>

	<cffunction name="test022_insertData_shouldInsertDataAndReturnNewlyCreatedUUId_whenObjIdHasUUIdGeneratorAndNoObjIdIsSupplied" returntype="void">
		<cfscript>
			var poService = _getService( objectDirectories=[ "/tests/resources/PresideObjectService/basicEmptyComponents/" ] );
			var result    = "";
			var newId = "";

			poService.dbSync();

			newId = poService.insertData( objectName="object_1", data={
				label = "This is a test another test"
			} );

			super.assertEquals( 35, Len( newId ), "Expected a 35 character, CFML style, UUID. Received [#newId#] instead" );

			super.assert( poService.dataExists( objectname="object_1", filter={ id=newId, label="This is a test another test" } ), "Record was not created" );
		</cfscript>
	</cffunction>

	<cffunction name="test022_1_insertData_shouldSetDateCreated_whenInsertingData" returntype="void">
		<cfscript>
			var poService = _getService( objectDirectories=[ "/tests/resources/PresideObjectService/componentsWithRelationship/" ] );
			var result    = "";
			var newId     = "";
			var q         = new Query();

			poService.dbSync();

			newId = poService.insertData( objectName="object_a", data={
				label = "This is a test"
			} );

			q.setDatasource( application.dsn );
			q.setSQL( "select datecreated from ptest_object_a where id = '#newId#'" );
			result = q.execute().getResult();

			super.assert( DateDiff( "s", result.datecreated, Now() ) LTE 10, "Created date was not set to a time near now" );
		</cfscript>
	</cffunction>

	<cffunction name="test022_2_insertData_shouldSetDateModified_whenInsertingData" returntype="void">
		<cfscript>
			var poService = _getService( objectDirectories=[ "/tests/resources/PresideObjectService/componentsWithRelationship/" ] );
			var result    = "";
			var newId     = "";
			var q         = new Query();

			poService.dbSync();

			newId = poService.insertData( objectName="object_a", data={
				label = "This is a test"
			} );

			q.setDatasource( application.dsn );
			q.setSQL( "select datemodified from ptest_object_a where id = '#newId#'" );
			result = q.execute().getResult();

			super.assert( DateDiff( "s", result.datemodified, Now() ) LTE 10, "Modified date was not set to a time near now" );
		</cfscript>
	</cffunction>

	<cffunction name="test023_updateData_shouldUpdateDataMatchedByBasicFilter_andReturnNumberOfRecordsUpdated" returntype="void">
		<cfscript>
			var poService = _getService( objectDirectories=[ "/tests/resources/PresideObjectService/componentsWithRelationship/" ] );
			var result    = "";
			var q = new query();

			poService.dbSync();

			q.setDatasource( application.dsn );
			q.setSQL( "insert into ptest_object_a ( datecreated, datemodified, label ) values ( Now(), Now(), 'test1' ), ( Now(), Now(), 'test2'), ( Now(), Now(), 'test3'), ( Now(), Now(), 'test4')" );
			q.execute();

			super.assert( poService.dataExists( objectName="object_a" ), "Test failed, data should have been inserted into the table before attempting the delete" );

			result = poService.updateData(
				  objectName = "object_a"
				, data       = { label = "updated label" }
				, filter     = { id = [1,2,3] }
			);
			super.assertEquals( 3, result, "Expected updateData() to return 3 as the number of records updated" );

			q.setDatasource( application.dsn );
			q.setSQL( "select 1 from ptest_object_a where id in (1,2,3,4) and label = 'updated label'" );
			result = q.execute();

			super.assertEquals( 3, result.getResult().recordCount, "Records were not updated" );
		</cfscript>
	</cffunction>

	<cffunction name="test024_updateData_shouldThrowInformativeError_whenNoFilterPassedAndForceUpdateAllIsNotSet" returntype="void">
		<cfscript>
			var poService   = _getService( objectDirectories=[ "/tests/resources/PresideObjectService/componentsWithRelationship/" ] );
			var errorThrown = false;

			poService.dbSync();

			try {
				poService.updateData( objectName = "object_b", data={ label = 'hello' } );
			} catch( "PresideObjects.updateAllProtection" e ) {
				super.assertEquals( "A call to update records in [object_b] was made without any filter which would lead to all records being updated", e.message );
				super.assertEquals( "If you wish to update all records, you must set the [forceUpdateAll] argument of the [updateData] method to true", e.detail );
				errorThrown = true;
			}

			super.assert( errorThrown, "No informative error was thrown" );
		</cfscript>
	</cffunction>

	<cffunction name="test024_updateData_shouldUpdateAllRecords_whenNoFilterPassedAndForceUpdateAllIsSetToTrue" returntype="void">
		<cfscript>
			var poService   = _getService( objectDirectories=[ "/tests/resources/PresideObjectService/componentsWithRelationship/" ] );
			var q = new query();
			var result = "";

			poService.dbSync();

			q.setDatasource( application.dsn );
			q.setSQL( "insert into ptest_object_a ( datecreated, datemodified, label ) values ( Now(), Now(), 'test1' ), ( Now(), Now(), 'test2'), ( Now(), Now(), 'test3'), ( Now(), Now(), 'test4'), ( Now(), Now(), 'test5')" );
			q.execute();

			result = poService.updateData(
				  objectName     = "object_a"
				, data           = { label = 'label altered' }
				, forceUpdateAll = true
			);

			super.assertEquals( 5, result, "Expected all 5 records to have been updated. Method reported [#result#]" );

			q.setDatasource( application.dsn );
			q.setSQL( "select 1 from ptest_object_a where label = 'label altered'" );
			result = q.execute().getResult();

			super.assertEquals( 5, result.recordCount, "Records were not correctly updated" );
		</cfscript>
	</cffunction>

	<cffunction name="test025_updateData_shouldUpdateRecords_whenUsingCrossTableFilters" returntype="void">
		<cfscript>
			var poService = _getService( objectDirectories=[ "/tests/resources/PresideObjectService/componentsWithAutoJoinableRelationships/" ] );
			var q         = new Query();
			var result    = "";
			var eId       = CreateUUId();
			var bId       = CreateUUId();
			var bId2      = CreateUUId();
			var cId       = CreateUUId();
			var cId2      = CreateUUId();
			var fId       = CreateUUId();
			var fId2      = CreateUUId();

			poService.dbSync();

			q.setDatasource( application.dsn );
			q.setSQL( "insert into ptest_object_a ( datecreated, datemodified, label ) values ( Now(), Now(), 'a test' ), ( Now(), Now(), 'another test')" );
			q.execute();

			q.setSQL( "insert into ptest_object_e ( datecreated, datemodified, id, label ) values ( Now(), Now(), '#eId#','e test' )" );
			q.execute();

			q.setSQL( "insert into ptest_object_d ( datecreated, datemodified, label, object_e ) values ( Now(), Now(), 'd test', '#eId#' )" );
			q.execute();

			q.setSQL( "insert into ptest_object_b ( datecreated, datemodified, id, label, related_to_a, object_d ) values (  Now(), Now(), '#bId#', 'b test', 1, 1 ),(  Now(), Now(), '#bId2#', 'b test', 2, 1 )" );
			q.execute();

			q.setSQL( "insert into ptest_object_c ( datecreated, datemodified, id, label, object_b ) values (  Now(), Now(), '#cId#', 'testing c', '#bId#' ),(  Now(), Now(), '#cId2#', 'testing c 2', '#bId2#' )" );
			q.execute();

			q.setSQL( "insert into ptest_object_f ( datecreated, datemodified, id, label, object_c ) values (  Now(), Now(), '#fId#', 'testing f', '#cId#' ),(  Now(), Now(), '#fId2#', 'testing f again', '#cId2#' )" );
			q.execute();

			result = poService.updateData(
				  objectName = "object_f"
				, data = { label = "changed" }
				, filter = { "object_b.related_to_a" = [1,3,5,6] }
			);

			super.assertEquals( 1, result, "Expected only one record to match the filter and be updated. Method reported [#result#]" );

			q.setSQL( "select label from ptest_object_f where id = '#fId#' and label = 'changed'" );
			result = q.execute().getResult();

			super.assertEquals( 1, result.recordCount, "Record was not updated as expected" );
		</cfscript>
	</cffunction>

	<cffunction name="test026_1_updateData_shouldUpdateRecords_whenUsingCrossTablePlainSqlFilters" returntype="void">
		<cfscript>
			var poService = _getService( objectDirectories=[ "/tests/resources/PresideObjectService/componentsWithAutoJoinableRelationships/" ] );
			var q         = new Query();
			var result    = "";
			var eId       = CreateUUId();
			var bId       = CreateUUId();
			var bId2      = CreateUUId();
			var cId       = CreateUUId();
			var cId2      = CreateUUId();
			var fId       = CreateUUId();
			var fId2      = CreateUUId();

			poService.dbSync();

			q.setDatasource( application.dsn );
			q.setSQL( "insert into ptest_object_a ( datecreated, datemodified, label ) values ( Now(), Now(), 'a test' ), ( Now(), Now(), 'another test')" );
			q.execute();

			q.setSQL( "insert into ptest_object_e ( datecreated, datemodified, id, label ) values ( Now(), Now(), '#eId#','e test' )" );
			q.execute();

			q.setSQL( "insert into ptest_object_d ( datecreated, datemodified, label, object_e ) values ( Now(), Now(), 'd test', '#eId#' )" );
			q.execute();

			q.setSQL( "insert into ptest_object_b ( datecreated, datemodified, id, label, related_to_a, object_d ) values ( Now(), Now(), '#bId#', 'b test', 1, 1 ),(  Now(), Now(), '#bId2#', 'b test', 2, 1 )" );
			q.execute();

			q.setSQL( "insert into ptest_object_c ( datecreated, datemodified, id, label, object_b ) values ( Now(), Now(), '#cId#', 'testing c', '#bId#' ),(  Now(), Now(), '#cId2#', 'testing c 2', '#bId2#' )" );
			q.execute();

			q.setSQL( "insert into ptest_object_f ( datecreated, datemodified, id, label, object_c ) values ( Now(), Now(), '#fId#', 'testing f', '#cId#' ),( Now(), Now(),  '#fId2#', 'testing f again', '#cId2#' )" );
			q.execute();

			result = poService.updateData(
				  objectName = "object_f"
				, data = { label = "changed" }
				, filter = "object_b.related_to_a <= :object_b.related_to_a"
				, filterParams = { "object_b.related_to_a" = 2 }
			);

			super.assertEquals( 2, result, "Expected two records to match the filter and be updated. Method reported [#result#]" );

			q.setSQL( "select label from ptest_object_f where label = 'changed'" );
			result = q.execute().getResult();

			super.assertEquals( 2, result.recordCount, "Records were not updated as expected" );
		</cfscript>
	</cffunction>

	<cffunction name="test026_updateData_shouldSetDateModified_whenUpdatingRecords" returntype="void">
		<cfscript>
			var poService   = _getService( objectDirectories=[ "/tests/resources/PresideObjectService/componentsWithRelationship/" ] );
			var q = new query();
			var result = "";
			var record = "";

			poService.dbSync();

			q.setDatasource( application.dsn );
			q.setSQL( "insert into ptest_object_a ( datecreated, label, datemodified ) values ( Now(), 'test1',  '1980-12-09 03:15:34'), ( Now(), 'test2', '1980-12-09 03:15:34'), ( Now(), 'test3', '1980-12-09 03:15:34'), ( Now(), 'test4', '1980-12-09 03:15:34'), ( Now(), 'test5', '1980-12-09 03:15:34')" );
			q.execute();

			result = poService.updateData(
				  objectName     = "object_a"
				, data           = { label = 'label altered' }
				, forceUpdateAll = true
			);

			super.assertEquals( 5, result, "Expected all 5 records to have been updated. Method reported [#result#]" );

			q.setDatasource( application.dsn );
			q.setSQL( "select datemodified from ptest_object_a where label = 'label altered'" );
			result = q.execute().getResult();

			super.assertEquals( 5, result.recordCount, "Records were not correctly updated" );

			for( record in result ){
				super.assert( DateDiff( "s", record.datemodified, Now() ) LTE 10, "Date was not updated" );
			}
		</cfscript>
	</cffunction>

	<cffunction name="test027_selectData_shouldSelectAllDataAndAllColumns_whenNoArgumentsSupplied" returntype="void">
		<cfscript>
			var poService      = _getService( objectDirectories=[ "/tests/resources/PresideObjectService/componentsWithRelationship/" ] );
			var result         = "";
			var expectedFields = ["id", "label", "datecreated", "datemodified" ];
			var field          = "";
			var i              = 0;

			poService.dbSync();

			poService.insertData( objectName="object_a", data={ label="label 1" } );
			poService.insertData( objectName="object_a", data={ label="label 2" } );
			poService.insertData( objectName="object_a", data={ label="label 3" } );
			poService.insertData( objectName="object_a", data={ label="label 4" } );

			result = poService.selectData( objectname="object_a" );

			super.assertEquals( 4, result.recordCount, "Expected four records to be returned" );
			for( field in expectedFields ){
				super.assert( ListFindNoCase( result.columnList, field ), "[#field#] column missing from results" );
			}

			for( i=1; i lte 4; i++ ){
				super.assertEquals( "label #i#", result.label[i] );
			}
		</cfscript>
	</cffunction>

	<cffunction name="test028_selectData_shouldSelectAllDataAndSpecifiedColumns_whenColumnListIsSupplied" returntype="void">
		<cfscript>
			var poService      = _getService( objectDirectories=[ "/tests/resources/PresideObjectService/componentsWithRelationship/" ] );
			var result         = "";
			var expectedFields = ["id", "label" ];
			var field          = "";
			var i              = 0;

			poService.dbSync();

			poService.insertData( objectName="object_a", data={ label="label 1" } );
			poService.insertData( objectName="object_a", data={ label="label 2" } );
			poService.insertData( objectName="object_a", data={ label="label 3" } );
			poService.insertData( objectName="object_a", data={ label="label 4" } );

			result = poService.selectData( objectname="object_a", selectFields=expectedFields );

			super.assertEquals( 4, result.recordCount, "Expected four records to be returned" );
			super.assertEquals( 2, ListLen( result.columnList ), "Expected two columns to be retrieved (received [#result.columnList#])" );
			for( field in expectedFields ){
				super.assert( ListFindNoCase( result.columnList, field ), "[#field#] column missing from results" );
			}
		</cfscript>
	</cffunction>

	<cffunction name="test029_selectData_shouldAutomaticallyJoinRelevantTables_whenSelectListRefersToOtherObjects" returntype="void">
		<cfscript>
			var poService      = _getService( objectDirectories=[ "/tests/resources/PresideObjectService/componentsWithAutoJoinableRelationships/" ] );
			var result         = "";
			var field          = "";
			var i              = 0;
			var aId            = "";
			var bId            = "";
			var cId            = "";
			var dId            = "";
			var eId            = "";
			var fId            = "";

			poService.dbSync();

			aId = poService.insertData( objectName="object_a", data={ label="label 1" } );
			eId = poService.insertData( objectName="object_e", data={ label="label 2" } );
			dId = poService.insertData( objectName="object_d", data={ label="label 3", object_e=eId } );
			bId = poService.insertData( objectName="object_b", data={ label="label 4", related_to_a=aId, object_d=dId } );
			cId = poService.insertData( objectName="object_c", data={ label="label 5", object_b=bId } );
			fId = poService.insertData( objectName="object_f", data={ label="label 4", object_c=cId } );


			result = poService.selectData(
				  objectname   = "object_f"
				, selectFields = ListToArray( "object_d.label as d_label" )
			);

			super.assertEquals( 1, result.recordCount, "Expected 1 record to be returned" );
			super.assertEquals( "d_label", result.columnList, "Expected columnList to be 'd_label' received [#result.columnList#] instead" );
			super.assertEquals( "label 3", result.d_label );
		</cfscript>
	</cffunction>

	<cffunction name="test030_selectData_shouldAutomaticallyJoinReleventTables_whenFieldListIncludesFunctionCalls" returntype="void">
		<cfscript>
			var poService      = _getService( objectDirectories=[ "/tests/resources/PresideObjectService/componentsWithAutoJoinableRelationships/" ] );
			var result         = "";
			var field          = "";
			var i              = 0;
			var aId            = "";
			var bId            = "";
			var cId            = "";
			var dId            = "";
			var eId            = "";
			var fId            = "";

			poService.dbSync();

			aId = poService.insertData( objectName="object_a", data={ label="label 1" } );
			eId = poService.insertData( objectName="object_e", data={ label="label 2" } );
			dId = poService.insertData( objectName="object_d", data={ label="label 3", object_e=eId } );
			bId = poService.insertData( objectName="object_b", data={ label="label 4", related_to_a=aId, object_d=dId } );
			cId = poService.insertData( objectName="object_c", data={ label="label 5", object_b=bId } );
			fId = poService.insertData( objectName="object_f", data={ label="label 4", object_c=cId } );

			result = poService.selectData(
				  objectname   = "object_f"
				, selectFields = [ "Concat( object_d.label, Concat( object_e.label, object_c.label ) ) as uber_label" ]
			);

			super.assertEquals( 1, result.recordCount, "Expected 1 record to be returned" );
			super.assertEquals( "uber_label", result.columnList, "Expected columnList to be 'uber_label' received [#result.columnList#] instead" );
			super.assertEquals( "label 3label 2label 5", result.uber_label );
		</cfscript>
	</cffunction>

	<cffunction name="test030_1_selectData_shouldAutomaticallyJoinRelevantTables_whenJoinsIntimatedInSavedFilters" returntype="void">
		<cfscript>
			var poService      = _getService( objectDirectories=[ "/tests/resources/PresideObjectService/componentsWithAutoJoinableRelationships/" ] );
			var result         = "";
			var field          = "";
			var i              = 0;
			var aId            = "";
			var bId            = "";
			var cId            = "";
			var dId            = "";
			var eId            = "";
			var fId            = "";

			poService.dbSync();

			aId = poService.insertData( objectName="object_a", data={ label="label 1" } );
			eId = poService.insertData( objectName="object_e", data={ label="label 2" } );
			dId = poService.insertData( objectName="object_d", data={ label="label 3", object_e=eId } );
			bId = poService.insertData( objectName="object_b", data={ label="label 4", related_to_a=aId, object_d=dId } );
			cId = poService.insertData( objectName="object_c", data={ label="label 5", object_b=bId } );
			fId = poService.insertData( objectName="object_f", data={ label="label 4", object_c=cId } );

			mockFilterService.$( "getFilter" ).$args( "testfilter" ).$results( { filter={ "object_c$object_b.label" = "label 4" } } );

			result = poService.selectData(
				  objectname   = "object_f"
				, savedFilters = [ "testfilter" ]
			);

			super.assertEquals( 1, result.recordCount, "Expected 1 record to be returned" );
		</cfscript>
	</cffunction>

	<cffunction name="test031_selectData_shouldSelectDataUsingFilters" returntype="void">
		<cfscript>
			var poService = _getService( objectDirectories=[ "/tests/resources/PresideObjectService/componentsWithAutoJoinableRelationships/" ] );
			var result    = "";
			var field     = "";
			var aId       = "";
			var aId2      = "";
			var bId       = "";
			var bId2      = "";
			var dId       = "";
			var eId       = "";

			poService.dbSync();

			aId  = poService.insertData( objectName="object_a", data={ label="label 1" } );
			aId2 = poService.insertData( objectName="object_a", data={ label="label 1 a" } );
			eId  = poService.insertData( objectName="object_e", data={ label="label 2" } );
			dId  = poService.insertData( objectName="object_d", data={ label="label 3", object_e=eId } );
			bId  = poService.insertData( objectName="object_b", data={ label="label 4", related_to_a=aId , object_d=dId } );
			bId2 = poService.insertData( objectName="object_b", data={ label="label 5", related_to_a=aId2, object_d=dId } );

			result = poService.selectData(
				  objectname = "object_b"
				, filter     = { "object_a.id" = [ aId2,1000,22 ] }
			);

			super.assertEquals( 1, result.recordCount, "Expected 1 record to be returned" );
			super.assertEquals( "label 5", result.label );
		</cfscript>
	</cffunction>

	<cffunction name="test031_1_selectData_shouldSelectDataUsingPlainTextSqlFilters" returntype="void">
		<cfscript>
			var poService = _getService( objectDirectories=[ "/tests/resources/PresideObjectService/componentsWithAutoJoinableRelationships/" ] );
			var result    = "";
			var field     = "";
			var aId       = "";
			var aId2      = "";
			var bId       = "";
			var bId2      = "";
			var dId       = "";
			var eId       = "";

			poService.dbSync();

			aId  = poService.insertData( objectName="object_a", data={ label="label 1" } );
			aId2 = poService.insertData( objectName="object_a", data={ label="label 1 a" } );
			eId  = poService.insertData( objectName="object_e", data={ label="label 2" } );
			dId  = poService.insertData( objectName="object_d", data={ label="label 3", object_e=eId } );
			bId  = poService.insertData( objectName="object_b", data={ label="label 4", related_to_a=aId , object_d=dId } );
			bId2 = poService.insertData( objectName="object_b", data={ label="label 5", related_to_a=aId2, object_d=dId } );

			result = poService.selectData(
				  objectname   = "object_b"
				, filter       = "object_a.id = :object_a.id and DateDiff( Now(), object_d.datecreated ) <= :age"
				, filterParams = { "object_a.id" = 2, age = { value = 0, type="cf_sql_integer" } }
			);

			super.assertEquals( 1, result.recordCount, "Expected 1 record to be returned" );
			super.assertEquals( "label 5", result.label );
		</cfscript>
	</cffunction>


	<cffunction name="test032_selectData_shouldAllowSortingOfData" returntype="void">
		<cfscript>
			var poService = _getService( objectDirectories=[ "/tests/resources/PresideObjectService/componentsWithAutoJoinableRelationships/" ] );
			var result    = "";
			var expected  = "label 8,label 9,label 99,label 7,label 4,label 5,label 6,label 3,label 1,label 2";
			var eIds      = [];
			var dIds      = [];

			poService.dbSync();

			eId[1] = poService.insertData( objectName="object_e", data={ label="label 1" } );
			eId[2] = poService.insertData( objectName="object_e", data={ label="label 2" } );
			eId[3] = poService.insertData( objectName="object_e", data={ label="label 3" } );
			eId[4] = poService.insertData( objectName="object_e", data={ label="label 4" } );
			eId[5] = poService.insertData( objectName="object_e", data={ label="label 5" } );

			dId[1] = poService.insertData( objectName="object_d", data={ label="label 1" , object_e=eId[1] } );
			dId[1] = poService.insertData( objectName="object_d", data={ label="label 2" , object_e=eId[1] } );
			dId[1] = poService.insertData( objectName="object_d", data={ label="label 3" , object_e=eId[2] } );
			dId[1] = poService.insertData( objectName="object_d", data={ label="label 4" , object_e=eId[3] } );
			dId[1] = poService.insertData( objectName="object_d", data={ label="label 5" , object_e=eId[3] } );
			dId[1] = poService.insertData( objectName="object_d", data={ label="label 6" , object_e=eId[3] } );
			dId[1] = poService.insertData( objectName="object_d", data={ label="label 7" , object_e=eId[4] } );
			dId[1] = poService.insertData( objectName="object_d", data={ label="label 8" , object_e=eId[5] } );
			dId[1] = poService.insertData( objectName="object_d", data={ label="label 9" , object_e=eId[5] } );
			dId[1] = poService.insertData( objectName="object_d", data={ label="label 99", object_e=eId[5] } );

			result = poService.selectData(
				  objectname   = "object_d"
				, selectFields = ["object_d.label"]
				, orderBy      = "object_e.label desc, object_d.label"
			);
			result = ValueList( result.label );

			super.assertEquals( expected, result, "Sort order was incorrect" );
		</cfscript>
	</cffunction>

	<cffunction name="test033_selectData_shouldWorkWithAggregatesAndGroupBy" returntype="void">
		<cfscript>
			var poService = _getService( objectDirectories=[ "/tests/resources/PresideObjectService/componentsWithAutoJoinableRelationships/" ] );
			var result    = "";
			var eIds      = [];
			var dIds      = [];
			var expectedLabelList = "label 3,label 5,label 1,label 2,label 4";
			var expectedCountList = "3,3,2,1,1";

			poService.dbSync();

			eId[1] = poService.insertData( objectName="object_e", data={ label="label 1" } );
			eId[2] = poService.insertData( objectName="object_e", data={ label="label 2" } );
			eId[3] = poService.insertData( objectName="object_e", data={ label="label 3" } );
			eId[4] = poService.insertData( objectName="object_e", data={ label="label 4" } );
			eId[5] = poService.insertData( objectName="object_e", data={ label="label 5" } );

			dId[1] = poService.insertData( objectName="object_d", data={ label="label 1" , object_e=eId[1] } );
			dId[1] = poService.insertData( objectName="object_d", data={ label="label 2" , object_e=eId[1] } );
			dId[1] = poService.insertData( objectName="object_d", data={ label="label 3" , object_e=eId[2] } );
			dId[1] = poService.insertData( objectName="object_d", data={ label="label 4" , object_e=eId[3] } );
			dId[1] = poService.insertData( objectName="object_d", data={ label="label 5" , object_e=eId[3] } );
			dId[1] = poService.insertData( objectName="object_d", data={ label="label 6" , object_e=eId[3] } );
			dId[1] = poService.insertData( objectName="object_d", data={ label="label 7" , object_e=eId[4] } );
			dId[1] = poService.insertData( objectName="object_d", data={ label="label 8" , object_e=eId[5] } );
			dId[1] = poService.insertData( objectName="object_d", data={ label="label 9" , object_e=eId[5] } );
			dId[1] = poService.insertData( objectName="object_d", data={ label="label 99", object_e=eId[5] } );

			result = poService.selectData(
				  objectname   = "object_e"
				, selectFields = [ "Count( object_d.id ) as d_count", "object_e.label" ]
				, groupBy      = "object_e.label"
				, orderBy      = "d_count desc, object_e.label"
			);

			super.assertEquals( expectedLabelList, ValueList( result.label ), "Labels not in expected order" );
			super.assertEquals( expectedCountList, ValueList( result.d_count ), "Counts not in expected order or incorrect" );
		</cfscript>
	</cffunction>

	<cffunction name="test034_selectData_shouldAllowResultLimiting" returntype="void">
		<cfscript>
			var poService = _getService( objectDirectories=[ "/tests/resources/PresideObjectService/componentsWithAutoJoinableRelationships/" ] );
			var result    = "";
			var eIds      = [];

			poService.dbSync();

			eId[1] = poService.insertData( objectName="object_e", data={ label="label 1" } );
			eId[2] = poService.insertData( objectName="object_e", data={ label="label 2" } );
			eId[3] = poService.insertData( objectName="object_e", data={ label="label 3" } );
			eId[4] = poService.insertData( objectName="object_e", data={ label="label 4" } );
			eId[5] = poService.insertData( objectName="object_e", data={ label="label 5" } );

			result = poService.selectData(
				  objectName = "object_e"
				, maxRows    = 4
				, orderBy    = "label desc"
			);

			super.assertEquals( 4, result.recordCount, "Expected 4 results from selectData() call, received #result.recordCount# instead." );
			super.assertEquals( eId[2], result.id[4], "Last result should have been the second created record, it was not." );
		</cfscript>
	</cffunction>

	<cffunction name="test034_selectData_shouldAllowPagination" returntype="void">
		<cfscript>
			var poService = _getService( objectDirectories=[ "/tests/resources/PresideObjectService/componentsWithAutoJoinableRelationships/" ] );
			var result    = "";
			var eIds      = [];

			poService.dbSync();

			eId[1] = poService.insertData( objectName="object_e", data={ label="label 1" } );
			eId[2] = poService.insertData( objectName="object_e", data={ label="label 2" } );
			eId[3] = poService.insertData( objectName="object_e", data={ label="label 3" } );
			eId[4] = poService.insertData( objectName="object_e", data={ label="label 4" } );
			eId[5] = poService.insertData( objectName="object_e", data={ label="label 5" } );
			eId[6] = poService.insertData( objectName="object_e", data={ label="label 6" } );
			eId[7] = poService.insertData( objectName="object_e", data={ label="label 7" } );
			eId[8] = poService.insertData( objectName="object_e", data={ label="label 8" } );
			eId[9] = poService.insertData( objectName="object_e", data={ label="label 9" } );

			result = poService.selectData(
				  objectName = "object_e"
				, maxRows    = 3
				, startRow   = 4
				, orderBy    = "label"
			);

			super.assertEquals( 3, result.recordCount, "Expected 3 results from selectData() call, received #result.recordCount# instead." );
			super.assertEquals( eId[4], result.id[1], "Incorrect start row" );
			super.assertEquals( eId[6], result.id[3], "Incorrect end row" );
		</cfscript>
	</cffunction>

	<cffunction name="test035_getObjectProperites_shouldReturnThePropertiesOfThePassedObject" returntype="void">
		<cfscript>
			var poService = _getService( objectDirectories=[ "/tests/resources/PresideObjectService/componentsWithAutoJoinableRelationships/" ] );
			var result    = "";
			var key       = "";
			var expected  = {
				  datecreated  = { name="datecreated" , control="none"     , dbtype="datetime", generator="none", maxLength=0, relatedTo="none", relationship="none", required=true, type="date" }
				, datemodified = { name="datemodified", control="none"     , dbtype="datetime", generator="none", maxLength=0, relatedTo="none", relationship="none", required=true, type="date" }
				, id           = { name="id"          , control="none"     , dbtype="varchar" , generator="UUID", maxLength=35, relatedTo="none", relationship="none", required=true, type="string", pk=true }
				, label        = { name="label"       , control="textinput", dbtype="varchar" , generator="none", maxLength=250, relatedTo="none", relationship="none", required=true, type="string" }
				, object_d         = { name="object_d"        , control="default"  , dbtype="int"      , generator="none", maxLength=0,  relatedTo="object_d", relationship="many-to-one", required=false, type="string", onDelete="set null", onUpdate="cascade" }
				, related_to_a     = { name="related_to_a"    , control="default"  , dbtype="int"      , generator="none", maxLength=0,  relatedTo="object_a", relationship="many-to-one", required=true, type="string", onDelete="error", onUpdate="cascade" }
			};

			result = poService.getObjectProperties( objectName = "object_b" );

			for( key in result ){
				super.assert( StructKeyExists( expected, key ) );
				super.assertEquals( expected[ key ], result[ key ] );
			}
		</cfscript>
	</cffunction>

	<cffunction name="test035_01_getObjectProperty_shouldReturnTheAttributesOfThePassedObjectAndFieldCombination" returntype="void">
		<cfscript>
			var poService = _getService( objectDirectories=[ "/tests/resources/PresideObjectService/componentsWithAutoJoinableRelationships/" ] );
			var result    = "";
			var expected  = {
				  name         = "object_d"
				, control      = "default"
				, dbtype       = "int"
				, generator    = "none"
				, maxLength    = 0
				, relatedTo    = "object_d"
				, relationship = "many-to-one"
				, required     = false
				, type         = "string"
				, onDelete     = "set null"
				, onUpdate     = "cascade"
			};

			result = poService.getObjectProperty( objectName = "object_b", propertyName="object_d" );

			super.assertEquals( expected, result );
		</cfscript>
	</cffunction>

	<cffunction name="test036_fieldExists_shouldReturnFalse_whenFieldDoesNotExist" returntype="void">
		<cfscript>
			var poService = _getService( objectDirectories=[ "/tests/resources/PresideObjectService/componentsWithAutoJoinableRelationships/" ] );

			super.assertFalse( poService.fieldExists( objectName="object_a", fieldName="i_do_not_exist" ), "fieldExists() returned true for a field that does not exist." );
		</cfscript>
	</cffunction>

	<cffunction name="test037_fieldExists_shouldReturnTrue_whenFieldDoesExist" returntype="void">
		<cfscript>
			var poService = _getService( objectDirectories=[ "/tests/resources/PresideObjectService/componentsWithAutoJoinableRelationships/" ] );

			super.assert( poService.fieldExists( objectName="object_b", fieldName="object_d" ), "fieldExists() returned false for a field that does exist." );
		</cfscript>
	</cffunction>

	<cffunction name="test038_listObjects_shouldReturnEmptyArray_whenNoObjectsExistInTheFactory" returntype="void">
		<cfscript>
			var poService = _getService( objectDirectories=[ "/tests/resources/PresideObjectService/nonExistantDir/" ] );
			var expected  = [];
			var result    = poService.listObjects();

			super.assertEquals( expected, result );
		</cfscript>
	</cffunction>

	<cffunction name="test039_listObjectsShouldReturnAllObjectsInObjectDirs_sortedAlphabetically" returntype="void">
		<cfscript>
			var poService = _getService( objectDirectories=[ "/tests/resources/PresideObjectService/componentsWithRelationship" ] );
			var expected  = [ "object_a", "object_b", "object_c" ];
			var result    = poService.listObjects();

			super.assertEquals( expected, result );
		</cfscript>
	</cffunction>

	<cffunction name="test040_listForeignObjectsBlockingDelete_shouldReturnEmptyArray_whenRecordCanBeDeletedWithoutOrphaningAnyForeignKeyRecords" returntype="void">
		<cfscript>
			var poService = _getService( objectDirectories=[ "/tests/resources/PresideObjectService/componentsWithAutoJoinableRelationships/" ] );
			var q = new query();
			var result = "";

			poService.dbSync();

			q.setDatasource( application.dsn );
			q.setSQL( "insert into ptest_object_a ( label, datemodified, datecreated) values ('test', Now(), Now() )" );
			q.execute();

			result = poService.listForeignObjectsBlockingDelete(
				  objectName   = "object_a"
				, recordId     = 1
			);

			super.assertEquals( [], result );
		</cfscript>
	</cffunction>

	<cffunction name="test041_listForeignObjectsBlockingDelete_shouldReturnObjectsAndRecordCountsForObjectsThatHaveForeignKeyDataThatIsBlockingAGivenRecordFromBeingDeletedWithoutError" returntype="void">
		<cfscript>
			var poService = _getService( objectDirectories=[ "/tests/resources/PresideObjectService/componentsWithAutoJoinableRelationships/" ] );
			var q = new query();
			var result = "";
			var expected = [ { objectName="object_d", recordcount=2, fk="object_e" } ];

			poService.dbSync();

			q.setDatasource( application.dsn );
			q.setSQL( "insert into ptest_object_e ( id, label, datemodified, datecreated) values ( 'TEST-UUID', 'test', Now(), Now() )" );
			q.execute();
			q.setSQL( "insert into ptest_object_d ( object_e, label, datemodified, datecreated) values ( 'TEST-UUID', 'test1', Now(), Now() )" );
			q.execute();
			q.setSQL( "insert into ptest_object_d ( object_e, label, datemodified, datecreated) values ( 'TEST-UUID', 'test2', Now(), Now() )" );
			q.execute();

			result = poService.listForeignObjectsBlockingDelete(
				  objectName   = "object_e"
				, recordId     = "TEST-UUID"
			);

			super.assertEquals( expected, result );
		</cfscript>
	</cffunction>

	<cffunction name="test042_deleteRelatedData_shouldDeleteRelatedRecords" returntype="void">
		<cfscript>
			var poService = _getService( objectDirectories=[ "/tests/resources/PresideObjectService/componentsWithAutoJoinableRelationships/" ] );
			var q = new query();
			var result = "";
			var expected = [ { objectName="object_d", recordcount=2 } ];

			poService.dbSync();

			q.setDatasource( application.dsn );
			q.setSQL( "insert into ptest_object_e ( id, label, datemodified, datecreated) values ( 'TEST-UUID', 'test', Now(), Now() )" );
			q.execute();
			q.setSQL( "insert into ptest_object_d ( object_e, label, datemodified, datecreated) values ( 'TEST-UUID', 'test1', Now(), Now() )" );
			q.execute();
			q.setSQL( "insert into ptest_object_d ( object_e, label, datemodified, datecreated) values ( 'TEST-UUID', 'test2', Now(), Now() )" );
			q.execute();

			super.assert( poService.selectData( objectName="object_d" ).recordCount );

			result = poService.deleteRelatedData(
				  objectName   = "object_e"
				, recordId     = "TEST-UUID"
			);

			super.assertEquals( 2, result );

			cachebox.getCache( "defaultQueryCache" ).clearAll();
			super.assertFalse( poService.selectData( objectName="object_d" ).recordCount );
			super.assert( poService.selectData( objectName="object_e" ).recordCount );
		</cfscript>
	</cffunction>

	<cffunction name="test043_deleteRelatedData_shouldThrowInformativeError_whenOperationWouldCascadeMoreThanOneLevelDeep" returntype="void">
		<cfscript>
			var poService   = _getService( objectDirectories=[ "/tests/resources/PresideObjectService/componentsWithAutoJoinableRelationships/" ] );
			var result      = "";
			var field       = "";
			var aId         = "";
			var aId2        = "";
			var bId         = "";
			var bId2        = "";
			var dId         = "";
			var eId         = "";
			var cId         = "";
			var errorThrown = false;

			poService.dbSync();

			aId  = poService.insertData( objectName="object_a", data={ label="label 1" } );
			aId2 = poService.insertData( objectName="object_a", data={ label="label 1 a" } );
			eId  = poService.insertData( objectName="object_e", data={ label="label 2" } );
			dId  = poService.insertData( objectName="object_d", data={ label="label 3", object_e=eId } );
			bId  = poService.insertData( objectName="object_b", data={ label="label 4", related_to_a=aId , object_d=dId } );
			bId2 = poService.insertData( objectName="object_b", data={ label="label 5", related_to_a=aId2, object_d=dId } );
			cId  = poService.insertData( objectName="object_c", data={ label="label c", object_b=bId } );

			try {
				poService.deleteRelatedData(
					  objectName   = "object_a"
					, recordId     = aId
				);
			} catch( "PresideObjectService.CascadeDeleteTooDeep" e ) {
				super.assertEquals( "A cascading delete of a [object_a] record was prevented due to too many levels of cascade.", e.message );
				super.assertEquals( "Preside will only allow a single level of cascaded deletes", e.detail );
				errorThrown = true;
			}

			super.assert( errorThrown, "No informative error was thrown" );
		</cfscript>
	</cffunction>

	<cffunction name="test044_selectData_shouldPopulateDefaultQueryCacheOnFirstHit" returntype="void">
		<cfscript>
			var poService      = _getService( objectDirectories=[ "/tests/resources/PresideObjectService/basicEmptyComponents/" ] );
			var selectDataArgs = { objectName="object_1", filter="label is not null" };
			var cache          = cachebox.getCache( "defaultQueryCache" );
			var data           = "";
			var cacheKeys      = "";

			poService.dbSync();
			poService.insertData( objectName="object_1", data={ label="label 1" } );

			super.assertEquals( 0, ArrayLen( cache.getKeys() ), "The cache is not empty, aborting test" );

			data = poService.selectData( argumentCollection = selectDataArgs );

			cacheKeys = cache.getKeys();
			super.assertEquals( 1, ArrayLen( cacheKeys ), "The query was not placed into the cache" );

			super.assertEquals( data, cache.get( cacheKeys[1] ), "The cached query was not equal to the original fetched query" );
		</cfscript>
	</cffunction>

	<cffunction name="test045_selectData_shouldFetchDataFromCache_whenAlreadyFetchedFromDb" returntype="void">
		<cfscript>
			var poService      = _getService( objectDirectories=[ "/tests/resources/PresideObjectService/basicEmptyComponents/" ] );
			var selectDataArgs = { objectName="object_2", filter="label is not null" };
			var cache          = cachebox.getCache( "defaultQueryCache" );
			var data           = "";
			var cacheKeys      = "";
			var report         = "";

			poService.dbSync();
			poService.insertData( objectName="object_2", data={ label="some label" } );

			request.delete( "__cacheboxRequestCache" );
			super.assertEquals( 0, ArrayLen( cache.getKeys() ), "The cache is not empty, aborting test" );

			data = poService.selectData( argumentCollection = selectDataArgs );

			cacheKeys = cache.getKeys();
			super.assertEquals( 1, ArrayLen( cacheKeys ), "The query was not placed into the cache" );

			poService.selectData( argumentCollection = selectDataArgs );
			poService.selectData( argumentCollection = selectDataArgs );

			report = cache.getStoreMetadataReport();
			super.assert( StructKeyExists( report, cacheKeys[1] ) );
			super.assertEquals( 2, report[ cachekeys[1] ].hits, "The cache was not hit the predicted number of times" );
		</cfscript>
	</cffunction>

	<cffunction name="test046_selectData_shouldNotPutResultInCache_whenAskedNotTo" returntype="void">
		<cfscript>
			var poService      = _getService( objectDirectories=[ "/tests/resources/PresideObjectService/basicEmptyComponents/" ] );
			var selectDataArgs = { objectName="object_1", filter="label is not null", useCache=false };
			var cache          = cachebox.getCache( "defaultQueryCache" );
			var data           = "";
			var cacheKeys      = "";

			poService.dbSync();
			poService.insertData( objectName="object_1", data={ label="label 1" } );

			super.assertEquals( 0, ArrayLen( cache.getKeys() ), "The cache is not empty, aborting test" );

			data = poService.selectData( argumentCollection = selectDataArgs );

			super.assertEquals( 0, ArrayLen( cache.getKeys() ), "The cache is not empty but should be because we told selectData() not to" );
		</cfscript>
	</cffunction>

	<cffunction name="test047_selectData_shouldNOTFetchDataFromCache_whenAlreadyFetchedFromDbButAskedNotToUseCache" returntype="void">
		<cfscript>
			var poService      = _getService( objectDirectories=[ "/tests/resources/PresideObjectService/basicEmptyComponents/" ] );
			var selectDataArgs = { objectName="object_2", filter="label is not null" };
			var cache          = cachebox.getCache( "defaultQueryCache" );
			var data           = "";
			var cacheKeys      = "";
			var report         = "";

			poService.dbSync();
			poService.insertData( objectName="object_2", data={ label="some label" } );

			super.assertEquals( 0, ArrayLen( cache.getKeys() ), "The cache is not empty, aborting test" );

			data = poService.selectData( argumentCollection = selectDataArgs );

			cacheKeys = cache.getKeys();
			super.assertEquals( 1, ArrayLen( cacheKeys ), "The query was not placed into the cache" );

			selectDataArgs.useCache = false;
			poService.selectData( argumentCollection = selectDataArgs );
			poService.selectData( argumentCollection = selectDataArgs );

			report = cache.getStoreMetadataReport();
			super.assert( StructKeyExists( report, cacheKeys[1] ) );
			super.assertEquals( 1, report[ cachekeys[1] ].hits, "The cache was not hit the predicted number of times" );
		</cfscript>
	</cffunction>

	<cffunction name="test048_updateData_shouldClearRelatedObjectCaches_whenUpdateClauseIsRelatedToSingleRecord" returntype="void">
		<cfscript>
			var poService      = _getService( objectDirectories=[ "/tests/resources/PresideObjectService/basicEmptyComponents/" ] );
			var cache          = cachebox.getCache( "defaultQueryCache" );
			var data           = {};
			var cacheKeys      = "";
			var report         = "";
			var objId          = "";
			var key            = "";
			var cachedData     = "";

			poService.dbSync();
			objId = poService.insertData( objectName="object_1", data={ label="a label" } );
			poService.insertData( objectName="object_2", data={ label="another label" } );
			poService.insertData( objectName="object_2", data={ label="some label" } );
			poService.insertData( objectName="object_3", data={ label="labels 1" } );
			poService.insertData( objectName="object_3", data={ label="labels 2" } );

			request.delete( "__cacheboxRequestCache" );
			super.assertEquals( 0, ArrayLen( cache.getKeys() ), "The cache is not empty, aborting test" );

			data.set1 = poService.selectData( objectName="object_1", filter={ id = objId } );
			data.set2 = poService.selectData( objectName="object_1", filter="id = :id", filterParams={id=objId} );
			data.set3 = poService.selectData( objectName="object_1", filter="id = :id", filterParams={id="meh"} );
			data.set4 = poService.selectData( objectName="object_1", filter={ id = "meh" } );
			data.set5 = poService.selectData( objectName="object_1" );
			data.set6 = poService.selectData( objectName="object_2" );
			data.set7 = poService.selectData( objectName="object_3" );

			cacheKeys = cache.getKeys();
			super.assertEquals( 7, ArrayLen( cacheKeys ), "Test queries were not loaded into the cache" );

			poService.updateData( objectName="object_1", data={ label="changed" }, filter={ id = objId } );

			cacheKeys = cache.getKeys();
			super.assertEquals( 2, ArrayLen( cacheKeys ), "Related caches not cleared" );

			for( key in cacheKeys ){
				cachedData = cache.get( key );
				super.assertNotEquals( data.set1, cachedData, "Incorrect caches cleared" );
				super.assertNotEquals( data.set2, cachedData, "Incorrect caches cleared" );
				super.assertNotEquals( data.set3, cachedData, "Incorrect caches cleared" );
				super.assertNotEquals( data.set4, cachedData, "Incorrect caches cleared" );
				super.assertNotEquals( data.set5, cachedData, "Incorrect caches cleared" );
			}
		</cfscript>
	</cffunction>

	<cffunction name="test049_deleteData_shouldClearRelatedObjectCaches_whenDeleteClauseIsRelatedToSingleRecord" returntype="void">
		<cfscript>
			var poService      = _getService( objectDirectories=[ "/tests/resources/PresideObjectService/basicEmptyComponents/" ] );
			var cache          = cachebox.getCache( "defaultQueryCache" );
			var data           = {};
			var cacheKeys      = "";
			var report         = "";
			var objId          = "";
			var key            = "";
			var cachedData     = "";

			poService.dbSync();
			objId = poService.insertData( objectName="object_1", data={ label="a label" } );
			poService.insertData( objectName="object_2", data={ label="another label" } );
			poService.insertData( objectName="object_2", data={ label="some label" } );
			poService.insertData( objectName="object_3", data={ label="labels 1" } );
			poService.insertData( objectName="object_3", data={ label="labels 2" } );

			super.assertEquals( 0, ArrayLen( cache.getKeys() ), "The cache is not empty, aborting test" );

			data.set1 = poService.selectData( objectName="object_1", filter={ id = objId } );
			data.set2 = poService.selectData( objectName="object_1", filter="id = :id", filterParams={id=objId} );
			data.set3 = poService.selectData( objectName="object_1", filter="id = :id", filterParams={id="meh"} );
			data.set4 = poService.selectData( objectName="object_1", filter={ id = "meh" } );
			data.set5 = poService.selectData( objectName="object_1" );
			data.set6 = poService.selectData( objectName="object_2" );
			data.set7 = poService.selectData( objectName="object_3" );

			cacheKeys = cache.getKeys();
			super.assertEquals( 7, ArrayLen( cacheKeys ), "Test queries were not loaded into the cache" );

			poService.deleteData( objectName="object_1", filter={ id = objId } );

			cacheKeys = cache.getKeys();
			super.assertEquals( 2, ArrayLen( cacheKeys ), "Related caches not cleared" );

			for( key in cacheKeys ){
				cachedData = cache.get( key );
				super.assertNotEquals( data.set1, cachedData, "Incorrect caches cleared" );
				super.assertNotEquals( data.set2, cachedData, "Incorrect caches cleared" );
				super.assertNotEquals( data.set3, cachedData, "Incorrect caches cleared" );
				super.assertNotEquals( data.set4, cachedData, "Incorrect caches cleared" );
				super.assertNotEquals( data.set5, cachedData, "Incorrect caches cleared" );
			}
		</cfscript>
	</cffunction>

	<cffunction name="test050_updateData_shouldClearAllOfAnObjectsQueryCaches_whenFilterRelatesToMultipleRecords" returntype="void">
		<cfscript>
			var poService      = _getService( objectDirectories=[ "/tests/resources/PresideObjectService/basicEmptyComponents/" ] );
			var cache          = cachebox.getCache( "defaultQueryCache" );
			var data           = {};
			var cacheKeys      = "";
			var report         = "";
			var objId          = "";
			var key            = "";
			var cachedData     = "";

			poService.dbSync();
			objId = poService.insertData( objectName="object_1", data={ label="a label" } );
			poService.insertData( objectName="object_2", data={ label="another label" } );
			poService.insertData( objectName="object_2", data={ label="some label" } );
			poService.insertData( objectName="object_3", data={ label="labels 1" } );
			poService.insertData( objectName="object_3", data={ label="labels 2" } );

			request.delete( "__cacheboxRequestCache" );
			super.assertEquals( 0, ArrayLen( cache.getKeys() ), "The cache is not empty, aborting test" );

			data.set1 = poService.selectData( objectName="object_1", filter={ id = objId } );
			data.set2 = poService.selectData( objectName="object_1", filter="id = :id", filterParams={id=objId} );
			data.set3 = poService.selectData( objectName="object_1", filter="id = :id", filterParams={id="meh"} );
			data.set4 = poService.selectData( objectName="object_1", filter={ id = "meh" } );
			data.set5 = poService.selectData( objectName="object_1" );
			data.set6 = poService.selectData( objectName="object_2" );
			data.set7 = poService.selectData( objectName="object_3" );

			cacheKeys = cache.getKeys();
			super.assertEquals( 7, ArrayLen( cacheKeys ), "Test queries were not loaded into the cache" );

			poService.updateData( objectName="object_1", data={ label="changed" }, filter="label is not null" );

			cacheKeys = cache.getKeys();
			super.assertEquals( 2, ArrayLen( cacheKeys ), "Related caches not cleared" );

			for( key in cacheKeys ){
				cachedData = cache.get( key );
				super.assertNotEquals( data.set1, cachedData, "Incorrect caches cleared" );
				super.assertNotEquals( data.set2, cachedData, "Incorrect caches cleared" );
				super.assertNotEquals( data.set3, cachedData, "Incorrect caches cleared" );
				super.assertNotEquals( data.set4, cachedData, "Incorrect caches cleared" );
				super.assertNotEquals( data.set5, cachedData, "Incorrect caches cleared" );
			}

		</cfscript>
	</cffunction>

	<cffunction name="test051_deleteData_shouldClearAllOfAnObjectsQueryCaches_whenFilterRelatesToMultipleRecords" returntype="void">
		<cfscript>
			var poService      = _getService( objectDirectories=[ "/tests/resources/PresideObjectService/basicEmptyComponents/" ] );
			var cache          = cachebox.getCache( "defaultQueryCache" );
			var data           = {};
			var cacheKeys      = "";
			var report         = "";
			var objId          = "";
			var key            = "";
			var cachedData     = "";

			poService.dbSync();
			objId = poService.insertData( objectName="object_1", data={ label="a label" } );
			poService.insertData( objectName="object_2", data={ label="another label" } );
			poService.insertData( objectName="object_2", data={ label="some label" } );
			poService.insertData( objectName="object_3", data={ label="labels 1" } );
			poService.insertData( objectName="object_3", data={ label="labels 2" } );

			request.delete( "__cacheboxRequestCache" );
			super.assertEquals( 0, ArrayLen( cache.getKeys() ), "The cache is not empty, aborting test" );

			data.set1 = poService.selectData( objectName="object_1", filter={ id = objId } );
			data.set2 = poService.selectData( objectName="object_1", filter="id = :id", filterParams={id=objId} );
			data.set3 = poService.selectData( objectName="object_1", filter="id = :id", filterParams={id="meh"} );
			data.set4 = poService.selectData( objectName="object_1", filter={ id = "meh" } );
			data.set5 = poService.selectData( objectName="object_1" );
			data.set6 = poService.selectData( objectName="object_2" );
			data.set7 = poService.selectData( objectName="object_3" );

			cacheKeys = cache.getKeys();
			super.assertEquals( 7, ArrayLen( cacheKeys ), "Test queries were not loaded into the cache" );

			poService.deleteData( objectName="object_1", filter="label is not null" );

			cacheKeys = cache.getKeys();
			super.assertEquals( 2, ArrayLen( cacheKeys ), "Related caches not cleared" );

			for( key in cacheKeys ){
				cachedData = cache.get( key );
				super.assertNotEquals( data.set1, cachedData, "Incorrect caches cleared" );
				super.assertNotEquals( data.set2, cachedData, "Incorrect caches cleared" );
				super.assertNotEquals( data.set3, cachedData, "Incorrect caches cleared" );
				super.assertNotEquals( data.set4, cachedData, "Incorrect caches cleared" );
				super.assertNotEquals( data.set5, cachedData, "Incorrect caches cleared" );
			}

		</cfscript>
	</cffunction>

	<cffunction name="test052_updateData_shouldClearQueryCaches_forQueriesThatReferenceTheUpdatedObjectThroughJoins" returntype="void">
		<cfscript>
			var poService  = _getService( objectDirectories=[ "/tests/resources/PresideObjectService/componentsWithAutoJoinableRelationships/" ] );
			var cache      = cachebox.getCache( "defaultQueryCache" );
			var data       = {};
			var cacheKeys  = "";
			var report     = "";
			var objId      = "";
			var key        = "";
			var cachedData = "";
			var aId        = "";
			var eId        = "";
			var dId        = "";
			var bId        = "";

			poService.dbSync();
			aId = poService.insertData( objectName="object_a", data={ label="label 1" } );
			eId = poService.insertData( objectName="object_e", data={ label="label 2" } );
			dId = poService.insertData( objectName="object_d", data={ label="label 3", object_e=eId } );
			bId = poService.insertData( objectName="object_b", data={ label="label 4", related_to_a=aId, object_d=dId } );

			super.assertEquals( 0, ArrayLen( cache.getKeys() ), "The cache is not empty, aborting test" );

			data.set1 = poService.selectData( objectName="object_b", selectFields=[ "object_a.label as obja" ], filter={ id = objId } );
			data.set2 = poService.selectData( objectName="object_b", selectFields=[ "object_a.label as obja" ], filter="object_b.id = :id", filterParams={id=objId} );
			data.set3 = poService.selectData( objectName="object_b", selectFields=[ "object_a.label as obja" ], filter="object_b.id = :id", filterParams={id="meh"} );
			data.set4 = poService.selectData( objectName="object_b", filter={ id = "meh" } );
			data.set5 = poService.selectData( objectName="object_b" );
			data.set6 = poService.selectData( objectName="object_a" );
			data.set7 = poService.selectData( objectName="object_c" );

			cacheKeys = cache.getKeys();
			super.assertEquals( 7, ArrayLen( cacheKeys ), "Test queries were not loaded into the cache" );

			poService.updateData( objectName="object_a", data={ label="a new label" }, filter="label is not null" );

			cacheKeys = cache.getKeys();
			super.assertEquals( 3, ArrayLen( cacheKeys ), "Related caches not cleared" );

			for( key in cacheKeys ){
				cachedData = cache.get( key );
				super.assertNotEquals( data.set1, cachedData, "Incorrect caches cleared" );
				super.assertNotEquals( data.set2, cachedData, "Incorrect caches cleared" );
				super.assertNotEquals( data.set3, cachedData, "Incorrect caches cleared" );
				super.assertNotEquals( data.set6, cachedData, "Incorrect caches cleared" );
			}
		</cfscript>
	</cffunction>

	<cffunction name="test053_objectsWithSameNameInDifferentSourceFoldersShouldHaveTheirPropertiesMerged" returntype="void">
		<cfscript>
			var poService                = _getService( objectDirectories=[ "/tests/resources/PresideObjectService/objectsWithMerging/folder1", "/tests/resources/PresideObjectService/objectsWithMerging/folder2" ] );
			var obj                      = poService.getObject( "object_to_be_merged" );
			var mergedProperties         = poService.getObjectProperties( "object_to_be_merged" );
			var expectedMergedProperties = {
				  datecreated                 = { name="datecreated"                , control="none"     , dbtype="datetime", generator="none", maxLength=0, relatedTo="none", relationship="none", required=true, type="date" }
				, datemodified                = { name="datemodified"               , control="none"     , dbtype="datetime", generator="none", maxLength=0, relatedTo="none", relationship="none", required=true, type="date" }
				, id                          = { name="id"                         , control="none"     , dbtype="varchar" , generator="UUID", maxLength=35, relatedTo="none", relationship="none", required=true, type="string", pk=true }
				, label                       = { name="label"                      , control="textinput", dbtype="varchar" , generator="none", maxLength=250, relatedTo="none", relationship="none", required=true, type="string" }

				, propertyThatWillBePreserved = { name="propertyThatWillBePreserved", type="string" , dbtype="varchar", control="default", maxLength="0", relationship="none", relatedto="none", generator="none", required="false" }
				, propertyWhosTypeWillChange  = { name="propertyWhosTypeWillChange" , type="numeric", dbtype="varchar", control="default", maxLength="0", relationship="none", relatedto="none", generator="none", required="false" }
				, addedProperty               = { name="addedProperty"              , type="string" , dbtype="varchar", control="default", maxLength="0", relationship="none", relatedto="none", generator="none", required="false" }
			};
			var actualPropNames   = mergedProperties.keyArray();
			var expectedPropNames = [ 'addedProperty','datecreated','datemodified','id','label','propertyThatWillBePreserved','propertyWhosTypeWillChange' ];

			actualPropNames.sort( "textnocase" );

			super.assertEquals( expectedPropNames, actualPropNames );

			for( key in mergedProperties ){
				super.assertEquals( expectedMergedProperties[ key ], mergedProperties[ key ] );
			}
		</cfscript>
	</cffunction>

	<cffunction name="test054_objectsWithSameNameInDifferentSourceFoldersShouldHaveTheirMethodsMerged" returntype="void">
		<cfscript>
			var poService = _getService( objectDirectories=[ "/tests/resources/PresideObjectService/objectsWithMerging/folder1", "/tests/resources/PresideObjectService/objectsWithMerging/folder2" ] );
			var obj       = poService.getObject( "object_to_be_merged" );

			super.assertEquals( "I was preserved"        , obj.functionToBePreserved() );
			super.assertEquals( "changed"                , obj.functionToBeOverrided() );
			super.assertEquals( "private function result", obj.addedFunction() );
		</cfscript>
	</cffunction>

	<cffunction name="test055_objectIsVersioned_shouldReturnFalse_forObjectsThatDoNotUseVersioning" returntype="void">
		<cfscript>
			var poService = _getService( objectDirectories=[ "/tests/resources/PresideObjectService/objectsWithMerging/folder1", "/tests/resources/PresideObjectService/objectsWithMerging/folder2" ] );

			super.assertFalse( poService.objectIsVersioned( "object_to_be_merged" ) );
		</cfscript>
	</cffunction>

	<cffunction name="test056_objectIsVersioned_shouldReturnTrue_forObjectsThatUseVersioning" returntype="void">
		<cfscript>
			var poService = _getService( objectDirectories=[ "/tests/resources/PresideObjectService/objectsWithVersioning" ] );

			super.assert( poService.objectIsVersioned( "an_object_with_versioning" ) );
		</cfscript>
	</cffunction>

	<cffunction name="test057_versionedObjectsShouldHaveVersionTableAutoCreatedInTheDatabase" returntype="void">
		<cfscript>
			var poService      = _getService( objectDirectories=[ "/tests/resources/PresideObjectService/objectsWithVersioning" ] );
			var expectedTables = [ "_preside_generated_entity_versions", "_version_number_sequence", "_version_ptest_a_category_object", left("_version_ptest_category_join_object",_getDbAdapter().getTableNameMaxLength() ), "_version_ptest_an_object_with_versioning", "ptest_a_category_object", "ptest_category_join_object", "ptest_an_object_with_versioning" ];
			var tables         = "";

			poService.dbSync();

			tables = ListToArray( _getDbTables() );
			tables.sort( "textnocase" );
			expectedTables.sort( "textnocase" );

			super.assertEquals( expectedTables, tables );
		</cfscript>
	</cffunction>

	<cffunction name="test058_versionedObjectTables_shouldHaveUniqueIndexesRemoved" returntype="void">
		<cfscript>
			var poService = _getService( objectDirectories=[ "/tests/resources/PresideObjectService/objectsWithVersioning" ] );
			var indexes   = "";

			poService.dbSync();

			indexes = _getTableIndexes( "_version_ptest_an_object_with_versioning" );

			for( var ix in indexes ) {
				super.assertFalse( indexes[ ix ].unique );
			}
		</cfscript>
	</cffunction>

	<cffunction name="test059_versionedObjectTables_shouldHaveNoForeignKeyConstraints" returntype="void">
		<cfscript>
			var poService = _getService( objectDirectories=[ "/tests/resources/PresideObjectService/objectsWithVersioning" ] );
			var fks       = "";

			poService.dbSync();

			fks = _getTableForeignKeys( "_version_ptest_an_object_with_versioning" );

			super.assert( StructIsEmpty( fks ) );
		</cfscript>
	</cffunction>

	<cffunction name="test060_versionedObjectsShouldHaveExtraColumnForVersionNumber" returntype="void">
		<cfscript>
			var poService   = _getService( objectDirectories=[ "/tests/resources/PresideObjectService/objectsWithVersioning" ] );
			var columns     = "";
			var columnNames = "";

			poService.dbSync();

			columns     = _getTableColumns( "_version_ptest_an_object_with_versioning" );
			columnNames = ValueList( columns.column_name );

			super.assert( ListFindNoCase( columnNames, "_version_number" ) );
		</cfscript>
	</cffunction>

	<cffunction name="test061_getNextVersionNumber_shouldReturnNewlyGeneratedVersionNumber" returntype="void">
		<cfscript>
			var poService   = _getService( objectDirectories=[ "/tests/resources/PresideObjectService/objectsWithVersioning" ] );

			poService.dbSync();

			super.assertEquals( 1, poService.getNextVersionNumber() );
			super.assertEquals( 2, poService.getNextVersionNumber() );
			super.assertEquals( 3, poService.getNextVersionNumber() );
			super.assertEquals( 4, poService.getNextVersionNumber() );
		</cfscript>
	</cffunction>

	<cffunction name="test0_62_insertData_shouldAddVersionRecord_forVersionedObject" returntype="void">
		<cfscript>
			var poService   = _getService( objectDirectories=[ "/tests/resources/PresideObjectService/objectsWithVersioning" ] );

			poService.dbSync();

			var newId          = poService.insertData( "a_category_object", { label="my new label" } );
			var versionRecords = poService.selectData( "vrsn_a_category_object" );
			var records        = poService.selectData( "a_category_object" );

			super.assertEquals( 1, versionRecords.recordCount );
			super.assertEquals( 1, records.recordCount );
			for( var record in versionRecords ) {
				super.assertEquals( 1    , record._version_number );
				super.assertEquals( newId, record.id );
			}
		</cfscript>
	</cffunction>

	<cffunction name="test0_63_insertData_shouldCreateVersionedManyToManyRecords_whenObjectUsesVersioning" returntype="void">
		<cfscript>
			var poService = _getService( objectDirectories=[ "/tests/resources/PresideObjectService/objectsWithVersioning" ] );
			var catIds    = [];

			poService.dbSync();

			poService.insertData( "a_category_object", { label="my new label 0" } );
			catIds.append( poService.insertData( "a_category_object", { label="my new label 1" } ) );
			catIds.append( poService.insertData( "a_category_object", { label="my new label 2" } ) );
			catIds.append( poService.insertData( "a_category_object", { label="my new label 3" } ) );
			catIds.append( poService.insertData( "a_category_object", { label="my new label 4" } ) );
			poService.insertData( "a_category_object", { label="my new label 5" } );
			poService.insertData( "a_category_object", { label="my new label 6" } );

			var newId = poService.insertData(
				  objectName = "an_object_with_versioning"
				, insertManyToManyRecords = true
				, data = {
					  label             = "myLabel"
					, a_category_object = ArrayToList( catIds )
				  }
			);
			var versionRecord = poService.selectData( "vrsn_an_object_with_versioning" );

			super.assertEquals( 1, versionRecord.recordCount );
			var multiRecords  = poService.selectData( objectName="vrsn_category_join_object", filter={ _version_number = versionRecord._version_number } );

			super.assertEquals( 4, multiRecords.recordCount );
			for( var record in multiRecords ){
				super.assertEquals( newId, record.an_object_with_versioning );
				super.assert( ArrayFind( catIds, record.a_category_object ) );
				ArrayDelete( catIds, record.a_category_object );
			}
		</cfscript>
	</cffunction>

	<cffunction name="test064_updateData_shouldCreateVersionRecordsForEachUpdatedRecord" returntype="void">
		<cfscript>
			var poService = _getService( objectDirectories=[ "/tests/resources/PresideObjectService/objectsWithVersioning" ] );
			var catIds    = [];

			poService.dbSync();

			poService.insertData( "a_category_object", { label="odd label 1" } );
			catIds.append( poService.insertData( "a_category_object", { label="my new label 1" } ) );
			catIds.append( poService.insertData( "a_category_object", { label="my new label 2" } ) );
			catIds.append( poService.insertData( "a_category_object", { label="my new label 3" } ) );
			catIds.append( poService.insertData( "a_category_object", { label="my new label 4" } ) );
			poService.insertData( "a_category_object", { label="odd label 2" } );
			poService.insertData( "a_category_object", { label="odd label 3" } );

			poService.updateData(
				  objectName   = "a_category_object"
				, filter       = "a_category_object.label like :a_category_object.label"
				, filterParams = { "a_category_object.label" = "my new label%" }
				, data         = { label = "changed" }
			);

			var versionRecords = poService.selectData(
				  objectName = "vrsn_a_category_object"
				, filter     = { _version_number = 8 }
			);
			var records = poService.selectData(
				  objectName = "a_category_object"
				, filter     = { label="changed" }
			);

			super.assertEquals( 4, versionRecords.recordCount );
			super.assertEquals( 4, records.recordCount );
			for( var record in versionRecords ){
				super.assertEquals( "changed", record.label );
				super.assertEquals( 8, record._version_number );
				super.assert( ArrayFind( catIds, record.id ) );
				ArrayDelete( catIds, record.id );
			}
		</cfscript>
	</cffunction>

	<cffunction name="test065_updateData_shouldNOTCreateVersionRecordsForEachUpdatedRecordWhenDataHasNotChanged" returntype="void">
		<cfscript>
			var poService = _getService( objectDirectories=[ "/tests/resources/PresideObjectService/objectsWithVersioning" ] );
			var catIds    = [];

			poService.dbSync();

			poService.insertData( "a_category_object", { label="odd label 1" } );
			catIds.append( poService.insertData( "a_category_object", { label="my new label 1" } ) );
			catIds.append( poService.insertData( "a_category_object", { label="my new label 2" } ) );
			catIds.append( poService.insertData( "a_category_object", { label="my new label 3" } ) );
			catIds.append( poService.insertData( "a_category_object", { label="my new label 4" } ) );
			poService.insertData( "a_category_object", { label="odd label 2" } );
			poService.insertData( "a_category_object", { label="odd label 3" } );

			poService.updateData(
				  objectName   = "a_category_object"
				, id           = catIds[2]
				, data         = { label = "my new label 2" }
			);

			var versionRecords = poService.selectData(
				  objectName = "vrsn_a_category_object"
				, filter     = { _version_number = 8 }
			);

			super.assertEquals( 0, versionRecords.recordCount );
		</cfscript>
	</cffunction>

	<cffunction name="test066_updateData_shouldMergeUnchangedDataFromExistingData" returntype="void">
		<cfscript>
			var poService = _getService( objectDirectories=[ "/tests/resources/PresideObjectService/objectsWithVersioning" ] );
			var catIds    = [];

			poService.dbSync();

			catIds.append( poService.insertData( "a_category_object", { label="my new label 1" } ) );
			catIds.append( poService.insertData( "a_category_object", { label="my new label 2" } ) );
			catIds.append( poService.insertData( "a_category_object", { label="my new label 3" } ) );

			var newId = poService.insertData(
				  objectName = "an_object_with_versioning"
				, insertManyToManyRecords = true
				, data = {
					  label             = "myLabel"
					, a_category_object = ArrayToList( catIds )
				  }
			);

			poService.updateData(
				  objectName              = "an_object_with_versioning"
				, id                      = newId
				, data                    = { a_many_to_one_relationship = catIds[1] }
				, updateManyToManyRecords = true
			);

			var versionRecord = poService.selectData(
				  objectName = "vrsn_an_object_with_versioning"
				, filter     = { _version_number = 5, id = newId }
			);

			super.assertEquals( 1, versionRecord.recordCount );
			super.assertEquals( "myLabel", versionRecord.label );
			super.assertEquals( catIds[1], versionRecord.a_many_to_one_relationship );

			var versionedRecords = poService.selectData(
				  objectName = "vrsn_category_join_object"
				, filter     = { _version_number = versionRecord._version_number }
			);
			super.assertEquals( catIds.len(), versionedRecords.recordCount );
			for( var record in versionedRecords ){
				super.assertEquals( newId, record.an_object_with_versioning );
				super.assert( ArrayFind( catIds, record.a_category_object ) );
				ArrayDelete( catIds, record.a_category_object );
			}
		</cfscript>
	</cffunction>

	<cffunction name="test067_updateData_shouldCreateVersionRecordsForChangedManyToManyData" returntype="void">
		<cfscript>
			var poService = _getService( objectDirectories=[ "/tests/resources/PresideObjectService/objectsWithVersioning" ] );
			var catIds    = [];

			poService.dbSync();

			catIds.append( poService.insertData( "a_category_object", { label="my new label 1" } ) );
			catIds.append( poService.insertData( "a_category_object", { label="my new label 2" } ) );
			catIds.append( poService.insertData( "a_category_object", { label="my new label 3" } ) );

			var newId = poService.insertData(
				  objectName = "an_object_with_versioning"
				, insertManyToManyRecords = true
				, data = {
					  label             = "myLabel"
					, a_category_object = ArrayToList( catIds )
				  }
			);
			catIds.deleteAt(1);
			poService.updateData(
				  objectName              = "an_object_with_versioning"
				, id                      = newId
				, data                    = { a_many_to_one_relationship = catIds[1], a_category_object = ArrayToList( catIds ) }
				, updateManyToManyRecords = true
			);

			var versionRecord = poService.selectData(
				  objectName = "vrsn_an_object_with_versioning"
				, filter     = { _version_number = 5, id = newId }
			);

			super.assertEquals( 1, versionRecord.recordCount );

			var versionedRecords = poService.selectData(
				  objectName = "vrsn_category_join_object"
				, filter     = { _version_number = versionRecord._version_number }
			);
			super.assertEquals( 2, versionedRecords.recordCount );
			for( var record in versionedRecords ){
				super.assertEquals( newId, record.an_object_with_versioning );
				super.assert( ArrayFind( catIds, record.a_category_object ) );
				ArrayDelete( catIds, record.a_category_object );
			}
		</cfscript>
	</cffunction>

	<cffunction name="test070_updateData_shouldMergeNonProvidedFieldsWithLatestVersionRecord_whenNoPublishedRecordExists" returntype="void">
		<cfscript>
			var poService = _getService( objectDirectories=[ "/tests/resources/PresideObjectService/objectsWithVersioning" ] );
			var catIds    = [];

			poService.dbSync();

			catIds.append( poService.insertData( "a_category_object", { label="my new label 1" } ) );
			catIds.append( poService.insertData( "a_category_object", { label="my new label 2" } ) );
			catIds.append( poService.insertData( "a_category_object", { label="my new label 3" } ) );

			var newId = poService.insertData(
				  objectName = "an_object_with_versioning"
				, insertManyToManyRecords = true
				, publish = false
				, data = {
					  label             = "myLabel"
					, a_category_object = ArrayToList( catIds )
				  }
			);

			poService.updateData(
				  objectName              = "an_object_with_versioning"
				, id                      = newId
				, data                    = { a_many_to_one_relationship = catIds[1] }
				, publish                 = false
				, updateManyToManyRecords = true
			);

			var versionRecord = poService.selectData(
				  objectName = "vrsn_an_object_with_versioning"
				, filter     = { _version_number = 5, id = newId }
			);

			super.assertEquals( 1, versionRecord.recordCount );
			super.assertEquals( "myLabel", versionRecord.label );
			super.assertEquals( catIds[1], versionRecord.a_many_to_one_relationship );

			var versionedRecords = poService.selectData(
				  objectName = "vrsn_category_join_object"
				, filter     = { _version_number = versionRecord._version_number }
			);
			super.assertEquals( catIds.len(), versionedRecords.recordCount );
			for( var record in versionedRecords ){
				super.assertEquals( newId, record.an_object_with_versioning );
				super.assert( ArrayFind( catIds, record.a_category_object ) );
				ArrayDelete( catIds, record.a_category_object );
			}
		</cfscript>
	</cffunction>

	<cffunction name="test071_selectData_shouldSelectLatestVersionFromVersionTable_whenSelectFromVersionTableIsSetToTrue" returntype="void">
		<cfscript>
			var poService = _getService( objectDirectories=[ "/tests/resources/PresideObjectService/objectsWithVersioning" ] );
			var catIds    = [];

			poService.dbSync();

			catIds.append( poService.insertData( "a_category_object", { label="my new label 1" } ) );
			catIds.append( poService.insertData( "a_category_object", { label="my new label 2" } ) );
			catIds.append( poService.insertData( "a_category_object", { label="my new label 3" } ) );

			var newId = poService.insertData(
				  objectName = "an_object_with_versioning"
				, insertManyToManyRecords = true
				, publish = false
				, data = {
					  label             = "myLabel"
					, a_category_object = ArrayToList( catIds )
				  }
			);

			poService.updateData(
				  objectName = "an_object_with_versioning"
				, insertManyToManyRecords = true
				, publish = false
				, id      = newId
				, data = { label="changed" }
			);

			var record = poService.selectData(
				  objectName       = "an_object_with_versioning"
				, id               = newId
				, fromVersionTable = true
			);

			super.assertEquals( 1, record.recordCount );
			super.assertEquals( "changed", record.label );
		</cfscript>
	</cffunction>

	<cffunction name="test073_selectData_shouldSelectSpecificVersion_whenSpecificVersionNumberSupplied" returntype="void">
		<cfscript>
			var poService = _getService( objectDirectories=[ "/tests/resources/PresideObjectService/objectsWithVersioning" ] );
			var catIds    = [];

			poService.dbSync();

			catIds.append( poService.insertData( "a_category_object", { label="my new label 1" } ) );
			catIds.append( poService.insertData( "a_category_object", { label="my new label 2" } ) );
			catIds.append( poService.insertData( "a_category_object", { label="my new label 3" } ) );

			var newId = poService.insertData(
				  objectName = "an_object_with_versioning"
				, insertManyToManyRecords = true
				, publish = false
				, data = {
					  label             = "myLabel"
					, a_category_object = ArrayToList( catIds )
				  }
			);

			poService.updateData(
				  objectName = "an_object_with_versioning"
				, insertManyToManyRecords = true
				, publish = false
				, id      = newId
				, data = { label="changed" }
			);

			poService.updateData(
				  objectName = "an_object_with_versioning"
				, insertManyToManyRecords = true
				, publish = false
				, id      = newId
				, data = { label="changed again" }
			);

			poService.updateData(
				  objectName = "an_object_with_versioning"
				, insertManyToManyRecords = true
				, publish = false
				, id      = newId
				, data = { label="changed once more" }
			);

			var record = poService.selectData(
				  objectName       = "an_object_with_versioning"
				, id               = newId
				, fromVersionTable = true
				, specificVersion  = 6
			);

			super.assertEquals( 1, record.recordCount );
			super.assertEquals( "changed again", record.label );
		</cfscript>
	</cffunction>

	<cffunction name="test074_selectData_shouldSelectVersionedManyToManyData" returntype="void">
		<cfscript>
			var poService = _getService( objectDirectories=[ "/tests/resources/PresideObjectService/objectsWithVersioning" ] );
			var catIds    = [];

			poService.dbSync();

			catIds.append( poService.insertData( "a_category_object", { label="my new label 1" } ) );
			catIds.append( poService.insertData( "a_category_object", { label="my new label 2" } ) );
			catIds.append( poService.insertData( "a_category_object", { label="my new label 3" } ) );

			var newId = poService.insertData(
				  objectName = "an_object_with_versioning"
				, insertManyToManyRecords = true
				, publish = false
				, data = {
					  label             = "myLabel"
					, a_category_object = ArrayToList( catIds )
				  }
			);

			ArrayDeleteAt( catIds, 1 );

			poService.updateData(
				  objectName = "an_object_with_versioning"
				, updateManyToManyRecords = true
				, publish = false
				, id      = newId
				, data = { label="changed", a_category_object = ArrayToList( catIds ) }
			);

			var records = poService.selectData(
				  objectName       = "an_object_with_versioning"
				, selectFields     = [ "a_category_object.id "]
				, id               = newId
				, fromVersionTable = true
			);

			super.assertEquals( 2, records.recordCount );
		</cfscript>
	</cffunction>

	<cffunction name="test075_updateData_shouldInsertNewRecord_whenPublishingAnExistingVersionRecordThatHasNotYetBeenPublished" returntype="void">
		<cfscript>
			var poService = _getService( objectDirectories=[ "/tests/resources/PresideObjectService/objectsWithVersioning" ] );
			var catIds    = [];

			poService.dbSync();

			catIds.append( poService.insertData( "a_category_object", { label="my new label 1" } ) );
			catIds.append( poService.insertData( "a_category_object", { label="my new label 2" } ) );
			catIds.append( poService.insertData( "a_category_object", { label="my new label 3" } ) );

			var newId = poService.insertData(
				  objectName = "an_object_with_versioning"
				, insertManyToManyRecords = true
				, publish = false
				, data = {
					  label             = "myLabel"
					, a_category_object = ArrayToList( catIds )
				  }
			);

			ArrayDeleteAt( catIds, 1 );

			poService.updateData(
				  objectName = "an_object_with_versioning"
				, updateManyToManyRecords = true
				, publish = true
				, id      = newId
				, data = { label="changed", a_category_object = ArrayToList( catIds ) }
			);

			var record = poService.selectData(
				  objectName       = "an_object_with_versioning"
				, id               = newId
			);
			super.assertEquals( 1, record.recordCount );

			var manyToManyrecords = poService.selectData(
				  objectName       = "an_object_with_versioning"
				, selectFields     = [ "a_category_object.id "]
				, id               = newId
			);
			super.assertEquals( 2, manyToManyrecords.recordCount );
		</cfscript>
	</cffunction>

	<cffunction name="test076_getRecordVersions_shouldReturnQueryOfAllVersionNumbersOfGivenRecordId" returntype="void">
		<cfscript>
			var poService = _getService( objectDirectories=[ "/tests/resources/PresideObjectService/objectsWithVersioning" ] );
			var id        = "";

			poService.dbSync();

			id = poService.insertData( "a_category_object", { label="my new label 1" } );

			poService.updateData( objectName="a_category_object", id=id, data={ label="changed 1" }, published=false );
			poService.updateData( objectName="a_category_object", id=id, data={ label="changed 2" } );
			poService.updateData( objectName="a_category_object", id=id, data={ label="changed 3" }, published=false );
			poService.updateData( objectName="a_category_object", id=id, data={ label="changed 4" } );

			// some other records to generate more versions that we don't want
			poService.insertData( "a_category_object", { label="my new label 2" } );
			poService.insertData( "a_category_object", { label="my new label 3" } );
			poService.insertData( "a_category_object", { label="my new label 4" } );

			var versions = poService.getRecordVersions( objectName="a_category_object", id=id );

			super.assertEquals( 5, versions.recordCount );
			super.assertEquals( "id,label,datecreated,datemodified,_version_number,_version_author,_version_changed_fields,_version_is_draft,_version_has_drafts,_version_is_latest,_version_is_latest_draft", versions.columnList );
			for( var i=1; i <= versions.recordCount; i++ ) {
				super.assertEquals( 6-i, versions._version_number[i] );
			}
		</cfscript>
	</cffunction>

	<cffunction name="test077_selectData_shouldUseDefinedLabelFieldInPlaceOfSelectField_whenSelectFieldDefinedWithSpecialLabelFieldSyntax" returntype="void">
		<cfscript>
			var poService = _getService( objectDirectories=[ "/tests/resources/PresideObjectService/objectsWithDifferentLabels" ] );

			poService.dbSync();

			var newId     = poService.insertData( "object_with_email_label", { email="test@test.com" } );
			var recordset = poService.selectData( objectName="object_with_email_label", id=newId, selectFields=[ "${labelfield} as label" ] );

			super.assertEquals( 1, recordSet.recordcount );
			super.assertEquals( "test@test.com", recordSet.label );
		</cfscript>
	</cffunction>

	<cffunction name="test078_selectData_shouldUseDefinedLabelFieldForRelatedObjectInPlaceOfSelectField_whenSelectFieldDefinedWithSpecialLabelFieldSyntax" returntype="void">
		<cfscript>
			var poService = _getService( objectDirectories=[ "/tests/resources/PresideObjectService/objectsWithDifferentLabels" ] );

			poService.dbSync();

			var newId     = poService.insertData( "object_with_email_label", { email="test2@test.com" } );
			var newId2    = poService.insertData( "object_with_normal_label", { label="whatever", relatedToEmailObject=newId } );
			var recordset = poService.selectData( objectName="object_with_normal_label", id=newId2, selectFields=[ "relatedToEmailObject.${labelfield} as emailLabel", "object_with_normal_label.label" ] );

			super.assertEquals( 1, recordSet.recordcount );
			super.assertEquals( "test2@test.com", recordSet.emailLabel );
		</cfscript>
	</cffunction>

	<cffunction name="test079_selectData_shouldThrowError_whenAttemptingToSelectLabelFieldOnAnObjectWithNoLabel" returntype="void">
		<cfscript>
			var poService   = _getService( objectDirectories=[ "/tests/resources/PresideObjectService/objectsWithDifferentLabels" ] );
			var errorThrown = false;

			poService.dbSync();

			try {
				poService.selectData( objectName="object_with_no_label", id="whatever", selectFields=[ "${labelfield} as label" ] );
			} catch( "PresideObjectService.no.label.field" e ) {
				super.assertEquals( "The object [object_with_no_label] has no label field", e.message );
				errorThrown = true;
			}

			super.assert( errorThrown, "A suitable error was not thrown" );
		</cfscript>
	</cffunction>

	<cffunction name="test080_insertData_shouldPopulateUnprovidedFieldsWithTheirDefaultValues" returntype="void">
		<cfscript>
			var poService = _getService( objectDirectories=[ "/tests/resources/PresideObjectService/objectsWithDefaults" ] );

			poService.dbSync();

			var obj       = poService.getObject( "object_with_defaulted_fields" );
			var recordId  = obj.insertData( data={ label="Hello world" } );
			var record    = obj.selectData( id=recordId );


			super.assertEquals( "property_a default", record.property_a );
			super.assertEquals( 0, DateDiff( "n", record.property_b, Now() ), "Generated date was not within a minute of now" );
			super.assertEquals( 1, record.property_c );
			super.assertEquals( "Hello world", record.property_d );
		</cfscript>
	</cffunction>

	<cffunction name="test081_dbSync_shouldNotCreateDbFieldsForOneToManyRelationshipTypeProperties" returntype="void">
		<cfscript>
			var poService = _getService( objectDirectories=[ "/tests/resources/PresideObjectService/componentsWithRelationship/" ] );

			poService.dbSync();

			var columns = _getDbTableColumns( "ptest_object_b" );

			super.assertFalse( columns.keyExists( "object_cs" ), "DBSync() created a field for a one-to-many relationship property, it should not have." );
		</cfscript>
	</cffunction>



<!--- private helpers --->
	<cffunction name="_dropAllTables" access="private" returntype="void" output="false">
		<cfset var tables = _getDbTables() />
		<cfset var table  = "" />
		<cfset var fks    = "" />
		<cfset var fk     = "" />

		<cfloop list="#tables#" index="table">
			<cfset fks = _getTableForeignKeys( table ) />
			<cfloop collection="#fks#" item="fk">
				<cfquery datasource="#application.dsn#">
					alter table #fks[fk].fk_table# drop foreign key #fk#
				</cfquery>
			</cfloop>
		</cfloop>
		<cfloop list="#tables#" index="table">
			<cfquery datasource="#application.dsn#">
				drop table #table#
			</cfquery>
		</cfloop>
	</cffunction>

	<cffunction name="_getService" access="private" returntype="any" output="false">
		<cfargument name="objectDirectories" type="array"  required="true" />
		<cfargument name="defaultPrefix"     type="string" required="false" default="ptest_" />

		<cfscript>
			cachebox               = _getCachebox( forceNewInstance = true );
			mockColdbox            = getMockbox().createEmptyMock( "preside.system.coldboxModifications.Controller" );
			mockColdboxEvent       = getMockbox().createStub();
			mockInterceptorService = _getMockInterceptorService();

			mockColdboxEvent.$( "isAdminUser", true );
			mockColdboxEvent.$( "getAdminUserId", "" );
			mockColdbox.$( "getRequestContext", mockColdboxEvent );

			return _getPresideObjectService(
				  objectDirectories  = arguments.objectDirectories
				, defaultPrefix      = arguments.defaultPrefix
				, forceNewInstance   = true
				, cacheBox           = cacheBox
				, coldbox            = mockColdbox
				, interceptorService = mockInterceptorService
			);
		</cfscript>
	</cffunction>

	<cffunction name="_getDbTables" access="private" returntype="string" output="false">
		<cfset var tables = new dbinfo( datasource="#application.dsn#" ).tables() />
		<cfreturn ValueList( tables.table_name ) />
	</cffunction>

	<cffunction name="_getDbTableColumns" access="private" returntype="struct" output="false">
		<cfargument name="table" type="string" required="true" />
		<cfset var columns = new dbinfo( datasource="#application.dsn#", table="#arguments.table#" ).columns() />
		<cfset var col     = "" />
		<cfset var cols    = {} />

		<cfscript>
			for( col in columns ){
				cols[ col.column_name ] = col;
			}

			return cols;
		</cfscript>
	</cffunction>

	<cffunction name="_getDbTableIndexes" access="private" returntype="struct" output="false">
		<cfargument name="table" type="string" required="true" />

		<cfscript>
			var indexes = new dbinfo( datasource="#application.dsn#", table="#arguments.table#" ).index();
			var index   = "";
			var ixs     = {};

			for( index in indexes ){
				if ( index.index_name neq "PRIMARY" ) {
					if ( not StructKeyExists( ixs, index.index_name ) ){
						ixs[ index.index_name ] = {
							  unique = not index.non_unique
							, fields = ""
						};
					}

					ixs[ index.index_name ].fields = ListAppend( ixs[ index.index_name ].fields, index.column_name );
				}
			}

			return ixs;
		</cfscript>
	</cffunction>

	<cffunction name="_getTableForeignKeys" access="private" returntype="struct" output="false">
		<cfargument name="table" type="string" required="true" />

		<cfscript>
			var keys        = new dbinfo( datasource="#application.dsn#", table="#arguments.table#" ).Foreignkeys();
			var key         = "";
			var constraints = {};
			var rules       = {};

			rules["0"] = "cascade";
			rules["2"] = "set null";

			for( key in keys ){
				constraints[ key.fk_name ] = {
					  pk_table  = key.pktable_name
					, fk_table  = key.fktable_name
					, pk_column = key.pkcolumn_name
					, fk_column = key.fkcolumn_name
				};

				if ( StructKeyExists( rules, key.update_rule ) ) {
					constraints[ key.fk_name ].on_update = rules[ key.update_rule ];
				} else {
					constraints[ key.fk_name ].on_update = "error";
				}

				if ( StructKeyExists( rules, key.delete_rule ) ) {
					constraints[ key.fk_name ].on_delete = rules[ key.delete_rule ];
				} else {
					constraints[ key.fk_name ].on_delete = "error";
				}
			}

			return constraints;
		</cfscript>
	</cffunction>

</cfcomponent>