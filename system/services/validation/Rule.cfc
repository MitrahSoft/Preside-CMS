<cfcomponent output=false accessors=true >

	<cfproperty name="fieldName"       type="string" default="">
	<cfproperty name="validator"       type="string" default="">
	<cfproperty name="params"          type="struct" default=StructNew()>
	<cfproperty name="message"         type="string" default="">
	<cfproperty name="serverCondition" type="string" default="">
	<cfproperty name="clientCondition" type="string" default="">
<cfscript>
	public struct function getMemento(){
		return {
			  fieldName       = getFieldName()
			, validator       = getValidator()
			, params          = getParams()
			, message         = getMessage()
			, serverCondition = getServerCondition()
			, clientCondition = getClientCondition()
		};
	}
</cfscript>
</cfcomponent>

