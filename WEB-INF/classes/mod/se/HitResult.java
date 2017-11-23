//
//	Copyright (c) 2006, EGI Technologies  All rights reserved.
//
/////////////////////////////////////////////////////////////////////
//
//	File: HitResult.java
//	Author: AGQ
//	Date:	06/16/06
//	Description: Search engine hit result bean.
//
//	Modification:
//
/////////////////////////////////////////////////////////////////////
//
package mod.se;

public class HitResult {
	private String id;
	private String query;
	private String path;
	private String contents;
		
	public HitResult() {
		super();
		this.id = null;
		this.query = null;
		this.path = null;
		this.contents = null;
	}
	
	/**
	 * Reads the information from cache file and highlights the result
	 * @return
	 */
	public String getContents() {
		return contents;
	}
	public String getId() {
		return id;
	}
	public String getPath() {
		return path;
	}
	public String getQuery() {
		return query;
	}

	public void setContents(String contents) {
		this.contents = contents;
	}
	public void setId(String id) {
		this.id = id;
	}
	public void setPath(String path) {
		this.path = path;
	}
	public void setQuery(String query) {
		this.query = query;
	}
	
	
}
