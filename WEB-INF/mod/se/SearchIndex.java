//
//	Copyright (c) 2006, EGI Technologies  All rights reserved.
//
/////////////////////////////////////////////////////////////////////
//
//	File: SearchIndex.java
//	Author: AGQ
//	Date:	06/16/06
//	Description: Search engine class responsible for holding and using the
//				search object.
//
//	Modification:
//
/////////////////////////////////////////////////////////////////////
//
package mod.se;

import java.io.IOException;
import java.util.Date;

//import javax.swing.text.Highlighter;
import org.apache.log4j.Logger;
import org.apache.lucene.analysis.Analyzer;
import org.apache.lucene.analysis.standard.StandardAnalyzer;
import org.apache.lucene.index.DirectoryReader;
import org.apache.lucene.index.IndexReader;
import org.apache.lucene.index.IndexWriter;
import org.apache.lucene.queryparser.classic.QueryParser;
import org.apache.lucene.search.BooleanQuery;
import org.apache.lucene.search.IndexSearcher;
import org.apache.lucene.search.Query;
import org.apache.lucene.search.TopDocs;
import org.apache.lucene.search.highlight.Highlighter;
import org.apache.lucene.search.highlight.QueryScorer;
import org.apache.lucene.search.highlight.SimpleFragmenter;
import org.apache.lucene.store.AlreadyClosedException;
import org.apache.lucene.queryparser.classic.ParseException;

import util.PrmLog;

public class SearchIndex {
	static IndexSearcher searcher = null;
	static Analyzer analyzer = null;
	static IndexReader reader = null;
	static final int MAX_HITS = 500;
	
	static Logger l = PrmLog.getLog();
	
	static final String FIELD = "contents";

	public static Analyzer getAnalyzer() {
		if (analyzer == null)
			reloadSearcher();
		return analyzer;
	}
	
	public static IndexReader getReader() {
		try {
			IndexWriter writer = IndexBuilder.getIndexWriter();
			if (reader == null) {
				reader = DirectoryReader.open(writer);
			}
			else {
				// this check requires the indexWriter to be opened
				IndexReader newReader;
				try {
					newReader = DirectoryReader.openIfChanged((DirectoryReader) reader);
					if (newReader != null) {
						reader.close();
						reader = newReader;
					}
				}
				catch (AlreadyClosedException e) {
					reader = DirectoryReader.open(writer);
				}
			}
		}
		catch (IOException e) {}

		return reader;
	}
	
	public static SearchResult getSearchResults(String query) {
		try {
			if (analyzer == null || reader == null || searcher == null)
				reloadSearcher();

			BooleanQuery.setMaxClauseCount(Integer.MAX_VALUE);
			//Query queryObj = new QueryParser(FIELD, analyzer).parse(query);	//(query, FIELD, analyzer);
/*			Query queryObj1 = new TermQuery(new Term(SEConstants.CONTENTS, query));
			Query queryObj2 = new TermQuery(new Term(SEConstants.FILENAME, query));
			BooleanQuery.Builder bld = new BooleanQuery.Builder();
			bld.add(new BooleanClause(queryObj1, BooleanClause.Occur.SHOULD));
			bld.add(new BooleanClause(queryObj2, BooleanClause.Occur.SHOULD));
			BooleanQuery bq = bld.build();
*/	
			QueryParser parser = new QueryParser(SEConstants.FILENAME, analyzer);
			Query q;
			q = parser.parse("contents:" + query);	// + " OR " + "filename:" + query);
		    System.out.println("Searching for: " + q.toString());
			
			TopDocs hits = searcher.search(q, MAX_HITS);
System.out.println("---*** search returns: " + hits.totalHits);
			
//			queryObj = queryObj.rewrite(reader);
//			Hits hits = searcher.search(queryObj);
			
			Highlighter highlighter = new Highlighter(new QueryScorer(q));
		    highlighter.setTextFragmenter(new SimpleFragmenter(40));    
		    return new SearchResult(hits, highlighter);
		} catch (NullPointerException e) {
			e.printStackTrace();
			l.warn(e);
			l.info("The NullPointerException in SearchIndex.java might be due to failing to obtain lock through the temp file in /Tomcat/temp/lucene*.lock.  Try remove these files and restart Tomcat.");
		} catch (IOException e) {
			l.error(e);
		}
		catch (ParseException e) {l.error(e);}
		return null;
	}
	
	/**
	 * Closes the current search index and reloads it. 
	 * This is use to search the more updated version 
	 * of the search in case results has been cached
	 * @return
	 */
	public static boolean reloadSearcher() {
		try {
			//if (!IndexStatus.isCurrentlyUsed()) {
			// ECC: Lucene should support read while index updating
				if (reader != null)
					reader.close();
				reader = getReader();
				//reader = IndexReader.open(IndexBuilder.getIndexDir());
				searcher = new IndexSearcher(reader);
				analyzer = new StandardAnalyzer();
				IndexStatus.setUpdated(false);
				System.out.println("Searcher reloaded " + new Date());
				return true;
//			}
//			else 
//				return false;
		} catch (IOException e) {
			l.error("Failed to reload searcher!!!");
			clearSearcher();
			return false;
		}
	}
	
	private static void clearSearcher() {
		reader = null;
		searcher = null;
		analyzer = null;
	}
}
