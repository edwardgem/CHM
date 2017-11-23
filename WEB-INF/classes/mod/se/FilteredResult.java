//
//	Copyright (c) 2006, EGI Technologies  All rights reserved.
//
/////////////////////////////////////////////////////////////////////
//
//	File: FilteredResult.java
//	Author: AGQ
//	Date:	06/16/06
//	Description: Search engine filtered results bean.
//
//	Modification:
//
/////////////////////////////////////////////////////////////////////
//
package mod.se;

import java.util.List;

import org.apache.lucene.document.Document;

public class FilteredResult {
	private List <Document> listDoc;
	private int[] intArr;
	
	public FilteredResult() {
		listDoc = null;
		intArr = null;
	}
	
	public FilteredResult(List<Document> listDoc, int[] intArr) {
		this.listDoc = listDoc;
		this.intArr = intArr;
	}

	public int[] getIntArr() {
		return intArr;
	}

	public List<Document> getListDoc() {
		return listDoc;
	}

	public void setIntArr(int[] intArr) {
		this.intArr = intArr;
	}

	public void setListDoc(List<Document> listDoc) {
		this.listDoc = listDoc;
	}
	
	
}
