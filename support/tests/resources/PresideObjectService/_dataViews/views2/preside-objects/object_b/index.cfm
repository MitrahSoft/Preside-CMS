<cf_presideparam name="args.title"       type="string" field="label" />
<cf_presideparam name="args.createdDate" type="string" field="datecreated" />

<cfoutput>
	<h1>#args.title#</h1>
	<p> #args.createdDate#</p>
</cfoutput>