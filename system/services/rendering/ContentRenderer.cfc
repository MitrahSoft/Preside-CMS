<cfcomponent output=false accessors=true> 
    <cfproperty name="viewlet" type="string" default=""> 
    <cfproperty name="chain"   type="array"  default=ArrayNew(1)> 

    <cfscript>
    	public boolean function isChain(){
			return ArrayLen( getChain() );
		}
    </cfscript> 
</cfcomponent>