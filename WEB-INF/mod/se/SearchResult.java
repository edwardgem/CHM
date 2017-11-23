//
//	Copyright (c) 2006, EGI Technologies  All rights reserved.
//
/////////////////////////////////////////////////////////////////////
//
//	File: SearchResult.java
//	Author: AGQ
//	Date:	06/16/06
//	Description: Bean to hold the search results for later usage.
//
//	Modification:
//
/////////////////////////////////////////////////////////////////////
//
package mod.se;

//import javax.swing.text.Highlighter;
import org.apache.lucene.search.TopDocs;
import org.apache.lucene.search.highlight.Highlighter;

public class SearchResult {
	private TopDocs hits;
	private Highlighter highlighter;
	
	public SearchResult() {
		hits = null;
		highlighter = null;
	}
	
	public SearchResult(TopDocs hits, Highlighter highlighter) {
		this();
		this.hits = hits;
		this.highlighter = highlighter;		
	}

	public Highlighter getHighlighter() {
		return highlighter;
	}

	public TopDocs getHits() {
		return hits;
	}

	public void setHighlighter(Highlighter highlighter) {
		this.highlighter = highlighter;
	}

	public void setHits(TopDocs hits) {
		this.hits = hits;
	}
	
	
}
