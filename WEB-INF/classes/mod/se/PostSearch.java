//
//	Copyright (c) 2006, EGI Technologies  All rights reserved.
//
/////////////////////////////////////////////////////////////////////
//
//	File: PostSearch.java
//	Author: AGQ
//	Date:	06/16/06
//	Description: Search engine servlet to retreive information from webpage.
//
//	Modification:
//			@010307ECC	Support begin with wildcard search.
//			@ECC050307a	Pericom requested feature: config to auto add wildcard
//						in the beginning and end of a single word search string.
//						Note that once search string begin with wildcard, it only
//						searches filename.
//
/////////////////////////////////////////////////////////////////////
//
package mod.se;

import java.io.IOException;
import java.io.UnsupportedEncodingException;
import java.net.URLEncoder;
import java.text.ParseException;
import java.text.SimpleDateFormat;
import java.util.Date;

import javax.servlet.ServletException;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import javax.servlet.http.HttpSession;

import oct.codegen.query;
import oct.codegen.queryManager;
import oct.codegen.result;
import oct.pmp.exception.PmpException;
import oct.pst.PstGuest;
import oct.pst.PstUserAbstractObject;

import org.apache.log4j.Logger;

import util.PrmLog;
import util.StringUtil;
import util.Util;

public class PostSearch extends HttpServlet{
	static final long serialVersionUID = 1001;
	static final String format = "MM/dd/yyyy";
	static final SimpleDateFormat DF = new SimpleDateFormat(format);
	static final String HOST = Util.getPropKey("pst", "PRM_HOST");
	static final String GUEST_SEARCH = Util.getPropKey("pst", "GUEST_SEARCH");
	static final String DEBUG_FLAG = Util.getPropKey("pst", "DEBUG_FLAG");
	static Logger l = PrmLog.getLog();
	public static final String DELIM = "::";
	static final String SEPARATOR = "* ;,\"";
	static final String AUTO_WILDCARD = Util.getPropKey("pst", "AUTO_WILDCARD");
	static final String DEF_SEARCH_FNAME = Util.getPropKey("pst", "DEFAULT_SEARCH_FILENAME");
	static final boolean isDEF_SEARCH_FNAME = ((DEF_SEARCH_FNAME!=null&&DEF_SEARCH_FNAME.equals("true"))?true:false);

	/**
	 * Retrieves all the information from search page
	 * and runs the retrieved query. Calls queryManagement
	 * to merges the results and returns an array of id.
	 */
	protected void doGet(HttpServletRequest request, HttpServletResponse response) throws ServletException, IOException {
		request.setCharacterEncoding("utf8");
		response.setCharacterEncoding("utf8");
		
		PstUserAbstractObject pstuser = null;
		HttpSession s = request.getSession(false);
		if (s != null)
			pstuser = (PstUserAbstractObject)s.getAttribute("pstuser");
		else
			s = request.getSession(true);
		if (pstuser == null) {
			try {
				if (GUEST_SEARCH != null && GUEST_SEARCH.equalsIgnoreCase("true")) {
					s = request.getSession(true);
					pstuser = (PstUserAbstractObject) PstGuest.getInstance();
					s.setAttribute("pstuser", pstuser);
				}
				else
				{
					response.sendRedirect(HOST + "/out.jsp?e=time out");
					return;
				}
			} catch (PmpException e) {
				l.error(e);
				response.sendRedirect(HOST);
				return;
			}
		}
		String query = request.getParameter("query");
		String keyword = request.getParameter("Keyword");
		String redirect = request.getParameter("redirect");
		String category = request.getParameter("Category");
		// Retrieve filters
		String rFilters = constructFilter(request);
		String settings = constructParameters(request);
		String filter = mod.se.Util.constructExpression(request, category);

System.out.println("PostSearch doGet() receive search query: ");
System.out.println("query="+query + "; keyword=" + keyword);

		// handle null
		if (query != null) {
			// remove the scope string "in project: "
			query = query.replace("in project:", "");
		}
		if (StringUtil.isNullOrEmptyString(query))
			query = keyword;

		if (query == null) {
			response.sendRedirect(HOST + "/ep/search.jsp?showFilter=true");
			return;
		}
		query = query.trim();

		// handle search pattern  E.g. +test +upload +internet (content search only)
		boolean isPlus = false;			// has plus sign, don't add auto wild
		if (query.length()>0 && query.charAt(0)=='+') isPlus = true;

		// ECC050307a
		boolean bAddedAutoWild = false;
		if (!isPlus && AUTO_WILDCARD!=null && AUTO_WILDCARD.equals("true"))
		{
			boolean bFound = false;
			for (int i=0; i<SEPARATOR.length(); i++)
			{
				if (query.indexOf(SEPARATOR.charAt(i)) != -1)
					{bFound = true; break;}
			}
			if (!bFound)
			{
				query = "*" + query + "*";
				bAddedAutoWild = true;
			}
		}

		// remove beginning *, ?
		//query = mod.se.Util.removeBadChar(query);
		//String modQuery = mod.se.Util.removeBadChar(query);	// ECC commented out: remove initial wildcard
		String modQuery = query;

		if (category == null || category.equalsIgnoreCase(oct.codegen.query.CAT_FILE))
		{
			if (modQuery != null && modQuery.trim().length() > 0)
			{
				// @AGQ092606
				//String modQuery = replaceParens(query);
				String queryPath = null;

				// @010307ECC support start with wildcard search
				modQuery = modQuery.trim();
				String oriModQuery = modQuery.replaceAll("\\*", "");
				oriModQuery = oriModQuery.replaceAll("\\?", "");

				// ECC: always add the a-z wildcard for filename search
/*
				String tail = "";
				if (modQuery.length()>1 && (modQuery.charAt(0)=='*' || modQuery.charAt(0)=='?'))
					tail = modQuery.substring(1);
				else if (!isPlus)
					tail = modQuery + "*";

				// add filename clause
				if (!isPlus)
				{
					modQuery = "";
					char c = 'a';
					for (int i=0; i<26; i++)
						modQuery += "filename:" + c++ + "*" + tail + " ";
					c = '0';
					for (int i=0; i<10; i++)
						modQuery += "filename:" + c++ + "*" + tail + " ";
					modQuery += "filename:" + tail;

					if (!bAddedAutoWild)
						queryPath = oriModQuery + " " + modQuery;
					else
						queryPath = modQuery;		// filename search only if AutoWild is true
				}
				else
				{
					queryPath = query;				// don't tamper with it
				}
*/
				queryPath = query;				
				
				
				//if (DEBUG_FLAG!=null && !DEBUG_FLAG.equals("0"))
				System.out.println("search: " + queryPath);

				SearchResult sr = SearchIndex.getSearchResults(queryPath);
				QueryManagement qm = new QueryManagement(pstuser);
				FilteredResult fr = qm.mergeData(sr, filter);

				s.setAttribute("sr", sr);
				s.setAttribute("fr", fr);
			}
			else if (filter.length() > 0) {
				QueryManagement qm = new QueryManagement(pstuser);
				FilteredResult fr = qm.mergeData(null, filter);
				s.setAttribute("sr", null);
				s.setAttribute("fr", fr);
			}
		}

		if (query != null) {
			try {
				query = URLEncoder.encode(query, "UTF-8");
			} catch (UnsupportedEncodingException e){
				l.error(e);
			}
		}

		if (redirect == null || redirect.length() == 0)
			redirect = "/ep/search.jsp";

		if (bAddedAutoWild) query = query.substring(1,query.length()-1);
		if (rFilters.length()>0 && !rFilters.endsWith("&")) rFilters = rFilters + "&";
		response.sendRedirect(HOST + redirect + "?" + rFilters + "Keyword=" + query + settings);
	}

	/**
	 * Saves the current search query into DB
	 */
	protected void doPost(HttpServletRequest request, HttpServletResponse response) throws ServletException, IOException {
		try {
			PstUserAbstractObject pstuser = null;
			HttpSession s = request.getSession(false);
			queryManager queryMgr = queryManager.getInstance();
			query qry = null;
			Date now = new Date();
			Date expireDate = null;
			Integer frequencyI = null;
			int savedQueryId = 0;
			boolean deleteQuery = false;
			StringBuffer sb = new StringBuffer();

			if (s != null)
				pstuser = (PstUserAbstractObject)s.getAttribute("pstuser");
			if (pstuser == null)
			{
				// the session might be timed out
				response.sendRedirect(HOST + "/out.jsp?go=" + HOST + "/ep/search.jsp?e=time out");
				return;
			}

			// Retrieve data from post
			String category = request.getParameter("Category"); // file, blog, min
			String rFilters = constructFilter(request); // filters in url form
			String filters = mod.se.Util.constructExpression(request, category); // filters in findID form
			String keyword = request.getParameter("Keyword"); // keyword search
			String delete = request.getParameter("Delete"); // true or false, delete this query?;

			String qname = request.getParameter("Query"); // name of query
			String description = request.getParameter("Description"); // description of query
			String savedQuery = request.getParameter("savedQuery"); // id of query to modify or delete
			//String activeQuery = request.getParameter("activeQuery"); // checked
			String frequencyS = request.getParameter("Frequency"); // 2 daily, 1 3x, 0 hourly
			//String stopDate = request.getParameter("StopDate"); // 1 has date, 0 never
			String expireDateS = request.getParameter("StopAt");

			String ownerId = String.valueOf(pstuser.getObjectId());

			// Handle null cases
			if (category==null) category = query.CAT_FILE;
			if (description==null) description = "";
			if (savedQuery==null || savedQuery.trim().length() == 0) savedQuery = "0";

			if (keyword == null) keyword = "";

			String expr = keyword + DELIM + rFilters + DELIM + filters;
			if (delete!=null && delete.equalsIgnoreCase("true"))
				deleteQuery = true;

			// Parse data into correct type
			try {
				if (frequencyS!=null)
					frequencyI = Integer.valueOf(frequencyS);
				else
					frequencyI = Integer.valueOf(-1);
				if (qname!=null)
					qname = qname.replaceAll("\\\\", "\\\\\\\\");
				if (savedQuery!=null)
					savedQueryId = Integer.parseInt(savedQuery);
				if (expireDateS!=null) {
					expireDate = DF.parse(expireDateS);
					Util.validCalanderDate(expireDateS, expireDate);
				}
				else {
					expireDate = DF.parse("12/31/9999");
				}
			} catch (NumberFormatException e) {
				l.error(e);
				sb.append("NumberFormatException\n");
			} catch (NullPointerException e) {
				l.error(e);
				sb.append("NullPointerException\n");
			} catch (ParseException e) {
				l.error(e);
				// Should only be date error
				sb.append("Please check to see that ExpireDate is in 01/13/06 format (month/date/year)<br>");
			}
			// Return if validation is not correct
			if (sb.length() > 0) {
				s.setAttribute("Error", sb.toString());
				l.error("Validation Error");
			}

			// Determine if it is a new query
			if(savedQueryId <= 0) {
				qry = (query)queryMgr.create(pstuser);
				qry.setAttribute("CreatedDate", now);
			}
			// Retrieve selected query
			else {
				qry = (query)queryMgr.get(pstuser, savedQueryId);
			}

			if (deleteQuery) {
				queryMgr.delete(qry);
			}
			// Update new or existing query
			else {
				qry.setAttribute("Category", category);
				qry.setAttribute("Description", description.getBytes());
				qry.setAttribute("ExpireDate", expireDate);
				qry.setAttribute("Expr", expr);
				qry.setAttribute("Frequency", frequencyI);
				qry.setAttribute("LastExecuteDate", now);
				qry.setAttribute("LastUpdatedDate", now);
				qry.setAttribute("Name", qname);
				qry.setAttribute("Owner", ownerId);

				queryMgr.commit(qry);
			}

			// perform a doGet on current query
			doGet(request, response);

		} catch (PmpException e) {
			l.error(e);
			response.sendRedirect(HOST + "/out.jsp?go=" + HOST + "/ep/search.jsp?e=time out");
			return;
		}
	}

	public static String constructFilter(HttpServletRequest request) {
		// construct expression
		StringBuffer sb = new StringBuffer();

		String category = request.getParameter("Category");
		String projName = request.getParameter("projName");
		String fromDate = request.getParameter("FromDate");
		String toDate = request.getParameter("ToDate");
		String postName = request.getParameter("postName");
		String accessName = request.getParameter("accessName");
		String projIdS = request.getParameter("scope");				// from JSP

		String [] blogType = {result.TYPE_BUG_BLOG, result.TYPE_TASK_BLOG, result.TYPE_ACTN_BLOG};
		String s;
		for (int i=0; i < blogType.length; i++)
		{
			s = request.getParameter(blogType[i]);
			if (s!=null && s.length()>0)
			{
				if (sb.length() > 0)
					sb.append("&");
				sb.append(blogType[i] + "=" + blogType[i]);
			}
		}

		if (category!=null && category.trim().length()>0) {
			if (sb.length() > 0)
				sb.append("&");
			sb.append("Category="+category);
		}

		if (projName!=null && projName.trim().length()>0) {
			if (sb.length() > 0)
				sb.append("&");
			sb.append("projName="+projName);
		}
		
		if (!StringUtil.isNullOrEmptyString(projIdS)) {
			if (sb.length() > 0)
				sb.append("&");
			sb.append("projName="+projIdS);
		}

		if (fromDate!=null && fromDate.trim().length() > 0 && !fromDate.equals("- -")) {
			if (sb.length() > 0)
				sb.append("&");
			sb.append("FromDate="+fromDate);
		}

		if (toDate!=null && toDate.trim().length() > 0 && !toDate.equals("- -")) {
			if (sb.length() > 0)
				sb.append("&");
			sb.append("ToDate="+toDate);
		}

		if (postName!=null && postName.trim().length() > 0) {
			if (sb.length() > 0)
				sb.append("&");
			sb.append("postName="+postName);
		}

		if (accessName!=null && accessName.trim().length() > 0) {
			if (sb.length() > 0)
				sb.append("&");
			sb.append("accessName="+accessName);
		}

		return sb.toString();
	}

	private static String constructParameters(HttpServletRequest request) {
		// construct expression
		StringBuffer sb = new StringBuffer();

		String showFilter = request.getParameter("showFilter");
		String showSavedQuery = request.getParameter("savedQuery");

		if (showFilter!=null && showFilter.trim().length()>0) {
			sb.append("&showFilter="+showFilter); // display filter
		}

		if (showSavedQuery!=null && showSavedQuery.trim().length()>0) {
			sb.append("&queryId="+showSavedQuery); // display select query info
		}

		sb.append("&rs=true"); // remember session

		return sb.toString();
	}

	/*
	private static String replaceSpChars(String query) {
		if (query != null && query.length() > 0) {
			StringBuffer sb = new StringBuffer();
			boolean isSpace = true;
			int length = query.length();
			for (int i=0; i<length; i++) {
				char curChar = query.charAt(i);
				switch (curChar) {
				case '~':
				case '^':
				case '[':
				case ']':
				case '{':
				case '}':
					sb.append('\\');
					sb.append(curChar);
					break;
				case '!':
				case '-':
				case ')':
				case '(':
				case '_':
					if (!isSpace)
						sb.append('?');
					break;
				case ' ':
					sb.append(curChar);
					isSpace = true;
					break;
				default:
					sb.append(curChar);
					isSpace = false;
					break;
				}
			}
			query = sb.toString();
		}
		return query;
	}
	*/
}
