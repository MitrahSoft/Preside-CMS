component output=false {

	public string function default( event, rc, prc, args={} ){
		var data = args.data ?: "";

		if ( IsDate( data ) ) {
			data = parseDateTime( data );
			return LSDateFormat(data,"long",getFwLocale()) & " " & LSTimeFormat( data, "medium" );
		}

		return data;
	}

}