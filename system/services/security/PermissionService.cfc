/**
 * Service that provides API methods for dealing with CMS admin permissions.
 * See [[cmspermissioning]] for a full guide to CMS users and permissions.
 *
 * @singleton
 * @autodoc
 *
 */
component displayName="Admin permissions service" {

// CONSTRUCTOR
	/**
	 * @loginService.inject       LoginService
	 * @cacheProvider.inject      cachebox:PermissionsCache
	 * @permissionsConfig.inject  coldbox:setting:adminPermissions
	 * @rolesConfig.inject        coldbox:setting:adminRoles
	 * @groupDao.inject           presidecms:object:security_group
	 * @userDao.inject            presidecms:object:security_user
	 * @contextPermDao.inject     presidecms:object:security_context_permission
	 */
	public any function init(
		  required any    loginService
		, required any    cacheProvider
		, required struct permissionsConfig
		, required struct rolesConfig
		, required any    groupDao
		, required any    userDao
		, required any    contextPermDao
	) {
		_setLoginService( arguments.loginService );
		_setCacheProvider( arguments.cacheProvider );
		_setGroupDao( arguments.groupDao );
		_setUserDao( arguments.userDao );
		_setContextPermDao( arguments.contextPermDao );

		_denormalizeAndSaveConfiguredRolesAndPermissions( arguments.permissionsConfig, arguments.rolesConfig );

		return this;
	}

// PUBLIC API METHODS
	/**
	 * Returns an array of admin user role names
	 * that have been configured for the application.
	 * \n
	 * See [[cmspermissioning]] for a full guide to CMS users and permissions.
	 *
	 * @autodoc
	 *
	 */
	public array function listRoles() {
		return _getRoles().keyArray();
	}

	/**
	 * Returns an array of permission keys that apply to the
	 * given arguments.
	 * \n
	 * See [[cmspermissioning]] for a full guide to CMS users and permissions.
	 *
	 * @autodoc
	 * @role.hint   If supplied, the method will return permission keys that the role has access to
	 * @group.hint  If supplied, the method will return permission keys that the group has access to
	 * @user.hint   If supplied, the method will return permission keys that the user has access to
	 * @filter.hint An array of filters with which to filter permission keys
	 *
	 */
	public array function listPermissionKeys( string role="", string group="", string user="", array filter=[] ) {
		if ( Len( Trim( arguments.role ) ) ) {
			return _getRolePermissions( arguments.role );

		} else if ( Len( Trim( arguments.group ) ) ) {
			return _getGroupPermissions( arguments.group );

		} else if ( Len( Trim( arguments.user ) ) ) {
			return _getUserPermissions( arguments.user );
		} else if ( arguments.filter.len() ) {
			return _filterPermissions( arguments.filter );
		}

		return _getPermissions();
	}

	/**
	 * Returns whether or not the user has permission to the given
	 * set of keys.
	 * \n
	 * See [[cmspermissioning]] for a full guide to CMS users and permissions.
	 *
	 * @autodoc
	 * @permissionKey.hint The permission key as defined in `Config.cfc`
	 * @context.hint       Optional named context
	 * @contextKeys.hint   Array of keys for the given context (required if context supplied)
	 * @userId.hint        ID of the user who's permissions we wish to check
	 * @userId.docdefault  ID of logged in user
	 *
	 */
	public boolean function hasPermission(
		  required string permissionKey
		,          string context       = ""
		,          array  contextKeys   = []
		,          string userId        = _getLoginService().getLoggedInUserId()
	) {
		if ( !Len( Trim( arguments.userId ) ) ) {
			return false;
		}

		if ( arguments.userId == _getLoginService().getLoggedInUserId() && _getLoginService().isSystemUser() ) {
			return true;
		}

		if ( Len( Trim( arguments.context ) ) && arguments.contextKeys.len() ) {
			var contextPerm = _getContextPermission( argumentCollection=arguments );
			if ( !IsNull( contextPerm ) && IsBoolean( contextPerm ) ) {
				return contextPerm;
			}
		}


		return listPermissionKeys( user=arguments.userId ).find( arguments.permissionKey );
	}

	/**
	 * Returns an array of user group IDs that the user is a member of
	 *
	 * @autodoc
	 * @userId.hint ID of the user who's groups we wish to get
	 *
	 */
	public array function listUserGroups( required string userId ) {
		var groups = _getUserDao().selectManyToManyData(
			  propertyName = "groups"
			, id           = arguments.userId
			, selectFields = [ "security_group" ]
		);

		return listToArray( ValueList( groups.security_group ) );
	}

	public struct function getContextPermissions(
		  required string  context
		, required array   contextKeys
		, required array   permissionKeys
		,          boolean includeDefaults=false
	) {
		var expandedPermissionKeys = listPermissionKeys( filter=permissionKeys );
		var contextPerms           = {};
		var dbData                 = "";

		for( var key in expandedPermissionKeys ){
			contextPerms[ key ] = {
				  granted = []
				, denied  = []
			};
		}

		if ( arguments.contextKeys.len() ) {
			dbData = _getContextPermDao().selectData(
				  selectFields = [ "granted", "permission_key", "security_group", "security_group.label as group_name" ]
				, filter       = {
					  context        = arguments.context
					, context_key    = arguments.contextKeys
					, permission_key = expandedPermissionKeys.sort( "textnocase" )
				  }
			);

			for( var record in dbData ){
				if ( record.granted ) {
					contextPerms[ record.permission_key ].granted.append( { id=record.security_group, name=record.group_name } );
				} else {
					contextPerms[ record.permission_key ].denied.append( { id=record.security_group, name=record.group_name } );
				}
			}
		}


		if ( arguments.includeDefaults ) {
			for( key in contextPerms ) {
				_getDefaultGroupsForPermission( permissionKey=key ).each( function( group ){
					if ( !contextPerms[ key ].granted.find( group ) ) {
						contextPerms[ key ].granted.append( group );
					}
				} );
			}
		}

		return contextPerms;
	}

	public boolean function syncContextPermissions( required string context, required string contextKey, required string permissionKey, required array grantedToGroups, required array deniedToGroups ) {
		transaction {
			_getContextPermDao().deleteData(
				filter = {
					  context        = arguments.context
					, context_key    = arguments.contextKey
					, permission_key = arguments.permissionKey
				}
			);

			for( var group in arguments.grantedToGroups ){
				_getContextPermDao().insertData(
					data = {
						  context        = arguments.context
						, context_key    = arguments.contextKey
						, permission_key = arguments.permissionKey
						, security_group = group
						, granted        = true
					}
				);
			}

			for( var group in arguments.deniedToGroups ){
				_getContextPermDao().insertData(
					data = {
						  context        = arguments.context
						, context_key    = arguments.contextKey
						, permission_key = arguments.permissionKey
						, security_group = group
						, granted        = false
					}
				);
			}

			_getCacheProvider().clearAll();
		}

		return true;
	}

// PRIVATE HELPERS
	private void function _denormalizeAndSaveConfiguredRolesAndPermissions( required struct permissionsConfig, required struct rolesConfig ) {
		_setPermissions( _expandPermissions( arguments.permissionsConfig ) );
		_setRoles( _expandRoles( arguments.rolesConfig ) );
	}

	private array function _getRolePermissions( required string role ) {
		var roles = _getRoles();

		return arrayLen(roles[ arguments.role ]) ? roles[ arguments.role ] : [];
	}

	private array function _getGroupPermissions( required string group ) {
		var roles = _getGroupDao().selectData( id=arguments.group, selectFields=[ "roles" ] );
		var perms = [];

		if ( !roles.recordCount ) {
			return [];
		}
		for( var role in ListToArray( roles.roles ) ){
			_getRolePermissions( role ).each( function( perm ){
				if ( !perms.find( perm ) ) {
					perms.append( perm );
				}
			} );
		}

		return perms;
	}

	private array function _getUserPermissions( required string user ) {
		var perms = [];
		var groups = listUserGroups( arguments.user );

		for( var group in groups ){
			_getGroupPermissions( group ).each( function( perm ){
				if ( !perms.find( perm ) ) {
					perms.append( perm );
				}
			} );
		}

		return perms;
	}

	private array function _filterPermissions( required array filter ) {
		var filtered   = [];
		var exclusions = [];
		var allPerms   = _getPermissions();

		for( var permissionKey in filter ){
			if ( IsSimpleValue( permissionKey ) ) {
				if ( Left( permissionKey, 1 ) == "!" ) {
					exclusions.append( ReReplace( permissionKey, "^!(.*)$", "\1" ) );

				} else if ( permissionKey contains "*" ) {
					var getPermissionKey = _expandWildCardPermissionKey( permissionKey );

					for ( var expandedKey in getPermissionKey ){
						if ( !filtered.findNoCase( expandedKey ) ) {
							filtered.append( expandedKey );
						}
					}
				} else if ( allPerms.findNoCase( permissionKey ) && !filtered.findNoCase( permissionKey ) ) {
					filtered.append( permissionKey );
				}
			}
		}

		for( var exclusion in exclusions ){
			if ( exclusion contains "*" ) {
				var getPermissionKey = _expandWildCardPermissionKey( exclusion );

				for ( var expandedKey in getPermissionKey ){
					filtered.delete( expandedKey );
				}
			} else {
				filtered.delete( exclusion );
			}
		}

		return filtered;
	}

	private any function _getContextPermission(
		  required string userId
		, required string permissionKey
		, required string context
		, required array  contextKeys
	) {
		var args               = arguments;
		var userGroups         = listUserGroups( arguments.userId );
		var cacheKey           = "ContextPermKeysForPermContextAndGroup: " & Hash( arguments.context & arguments.permissionKey & userGroups.toList() );
		var cachedContextPerms = _getCacheProvider().getOrSet( objectKey=cacheKey, produce=function(){
			var permsToCache = {};
			var permsFromDb  = _getContextPermDao().selectData(
				  selectFields = [ "Max( granted ) as granted", "context_key" ]
				, filter       = { context = args.context, permission_key = args.permissionKey, security_group = userGroups }
				, groupBy      = "context_key"
				, useCache     = false
			);

			for( var perm in permsFromDb ){
				permsToCache[ perm.context_key ] = perm.granted;
			}

			return permsToCache;
		} );


		if ( cachedContextPerms.isEmpty() ) {
			return;
		}

		for( var key in arguments.contextKeys ){
			if ( cachedContextPerms.keyExists( key ) ) {
				return cachedContextPerms[ key ];
			}
		}

		return;
	}

	private array function _expandPermissions( required struct permissions, string prefix="" ) {
		var expanded = [];

		for( var perm in permissions ){
			var newPrefix = ListAppend( arguments.prefix, perm, "." );

			if ( IsStruct( permissions[ perm ] ) ) {
				var childPerms = _expandPermissions( permissions[ perm ], newPrefix );
				for( var childPerm in childPerms ){
					expanded.append( childPerm );
				}
			} else if ( IsArray( permissions[ perm ] ) ) {
				for( var key in permissions[ perm ] ) {
					if ( IsSimpleValue( key ) ) {
						expanded.append( ListAppend( newPrefix, key, "." ) );
					}
				}
			}
		}

		return expanded;
	}

	private struct function _expandRoles( required struct roles ) {
		var expandedRoles = createObject("java", "java.util.LinkedHashMap").init();

		for( var roleName in arguments.roles ){
			var role = arguments.roles[ roleName ];
			var exclusions = [];

			expandedRoles[ roleName ] = [];

			if ( IsArray( role ) ) {
				expandedRoles[ roleName ] = listPermissionKeys( filter=role );
			}
		}

		return expandedRoles;
	}

	private array function _expandWildCardPermissionKey( required string permissionKey ) {
		var regex       = "^" & Replace( _reEscape( arguments.permissionKey ), "\*", "(.*?)", "all" ) & "$";
		var permissions = _getPermissions();

		return permissions.filter( function( permKey ){
			return ReFindNoCase( regex, permKey );
		} );
	}

	private string function _reEscape( required string stringToEscape ) {
		var charsToEscape = [ "\", "$","{","}","(",")","<",">","[","]","^",".","*","+","?","##",":","&" ];
		var escaped       = arguments.stringToEscape;

		for( var char in charsToEscape ){
			escaped = Replace( escaped, char, "\" & char, "all" );
		}

		return escaped;
	}

	private array function _getDefaultGroupsForPermission( required string permissionKey ) {
		var roles         = _getRoles();
		var rolesWithPerm = {};
		var groups        = [];

		for( var role in roles ){
			if ( roles[ role ].find( arguments.permissionKey ) ) {
				rolesWithPerm[ role ] = 1;
			}
		}

		if ( StructCount( rolesWithPerm ) ) {
			var allGroups = _getGroupDao().selectData(
				selectFields = [ "id", "label", "roles" ]
			);

			for( var group in allGroups ){
				for ( var role in ListToArray( group.roles ) ) {
					if ( rolesWithPerm.keyExists( role ) ) {
						groups.append( { id=group.id, name=group.label } );
						break;
					}
				}
			}
		}

		return groups;
	}

// GETTERS AND SETTERS
	private struct function _getRoles() {
		return _roles;
	}
	private void function _setRoles( required struct roles ) {
		_roles = arguments.roles;
	}

	private array function _getPermissions() {
		return _permissions;
	}
	private void function _setPermissions( required array permissions ) {
		_permissions = arguments.permissions;
	}

	private any function _getLoginService() {
		return _loginService;
	}
	private void function _setLoginService( required any loginService ) {
		_loginService = arguments.loginService;
	}

	private any function _getCacheProvider() {
		return _cacheProvider;
	}
	private void function _setCacheProvider( required any cacheProvider ) {
		_cacheProvider = arguments.cacheProvider;
	}

	private any function _getGroupDao() {
		return _groupDao;
	}
	private void function _setGroupDao( required any groupDao ) {
		_groupDao = arguments.groupDao;
	}

	private any function _getUserDao() {
		return _userDao;
	}
	private void function _setUserDao( required any userDao ) {
		_userDao = arguments.userDao;
	}

	private any function _getContextPermDao() {
		return _contextPermDao;
	}
	private void function _setContextPermDao( required any contextPermDao ) {
		_contextPermDao = arguments.contextPermDao;
	}
}