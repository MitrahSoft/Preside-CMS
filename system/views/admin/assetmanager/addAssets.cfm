<cfscript>
	prc.pageIcon     = "picture";
	prc.pageTitle    = translateResource( "cms:assetManager" );
	prc.pageSubTitle = translateResource( "cms:assetmanager.edit.uploads.title" );

	event.addAdminBreadCrumb(
		  title = translateResource( "cms:assetmanager.edit.uploads.title" )
		, link  = event.buildAdminLink( linkTo="assetmanager.editUploads" )
	);

	tempFileDetails = prc.tempFileDetails ?: {};

	saveBtnTitle = translateResource( "cms:assetManager.add.asset.form.save.button" );
	cancelBtnTitle = translateResource( "cms:assetManager.add.asset.form.cancel.button" );
</cfscript>

<cfoutput>
	<div id="add-asset-forms" class="add-asset-forms">
		<form id="add-assetGroup-form" class="form-horizontal add-asset-form" data-auto-focus-form="true" data-dirty-form="protect" action="#event.buildAdminLink( linkto="assetmanager.addAssetAction" )#" method="post">
			<div class="well">
				<input type="hidden" name="folder" value="#( rc.folder ?: "" )#" />
				<input type="hidden" name="assetForm" value="multiUpload" />
				<cfloop collection="#tempFileDetails#" item="tmpId">
					<cfif StructCount( tempFileDetails[tmpId] )>
						<input type="hidden" name="fileId" value="#tmpId#" />
						<div class="row">
							<div class="col-sm-2">
								<image src="#event.buildLink( assetId=tmpId, isTemporaryAsset=true )#" width="100" height="100" />
								<p>#tempFileDetails[ tmpId ].name#, #fileSizeFormat( tempFileDetails[ tmpId ].size )#</p>
							</div>
							<div class="col-sm-10">
							#renderForm(
									  formName        = "preside-objects.asset.admin.add"
									, formId          = "add-assetGroup-form"
									, context         = "admin"
									, savedData       = tempFileDetails[ tmpId ]
									, fieldNameSuffix = "_#tmpId#"
								)#
							</div>
						</div>
					</cfif>
				</cfloop>
				<div class="col-md-offset-2">
					<button type="reset" class="btn cancel-asset-btn"><i class="fa fa-remove-sign"></i> #cancelBtnTitle#</button>
					<button type="input" class="btn btn-primary"><i class="fa fa-check"></i> #saveBtnTitle#</button>
				</div>
			</div>
		</form>
		<div class="upload-completed-message">
			<h2 class="green"><i class="fa fa-check"></i>&nbsp;#translateResource( "cms:assetmanager.add.assets.complete.title" )#</h2>


			<p> #translateResource( "cms:assetmanager.add.assets.complete.message" )# </p>

			<a href="#event.buildAdminLink( linkTo="assetmanager", queryString="folder=#( rc.folder ?: '' )#")#" class="btn btn-primary back-btn">
				<i class="fa fa-step-backward"></i>
				#translateResource( "cms:assetmanager.add.assets.complete.button" )#
			</a>
		</div>
	</div>


</cfoutput>