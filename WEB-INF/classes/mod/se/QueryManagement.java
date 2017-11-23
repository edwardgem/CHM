//
//	Copyright (c) 2006, EGI Technologies  All rights reserved.
//
/////////////////////////////////////////////////////////////////////
//
//	File: QueryManagement.java
//	Author: AGQ
//	Date:	06/16/06
//	Description: Search engine query management.
//
//	Modification:
//		@ECC071906	Support multiple companies sharing PRM.
//		@AGQ091506	Only filter multiple companies when turned on.
// 		@AGQ091506a	Check if attachment is accessible by member.
//		@ECC031709	Restrictive access.
//
/////////////////////////////////////////////////////////////////////
//
package mod.se;

import java.io.BufferedReader;
import java.io.File;
import java.io.FileReader;
import java.io.IOException;
import java.io.StringReader;
import java.text.ParseException;
import java.text.SimpleDateFormat;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.Calendar;
import java.util.Date;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.regex.Matcher;
import java.util.regex.Pattern;

import oct.codegen.actionManager;
import oct.codegen.attachment;
import oct.codegen.attachmentManager;
import oct.codegen.bugManager;
import oct.codegen.meeting;
import oct.codegen.meetingManager;
import oct.codegen.planTask;
import oct.codegen.planTaskManager;
import oct.codegen.projectManager;
import oct.codegen.query;
import oct.codegen.queryManager;
import oct.codegen.result;
import oct.codegen.resultManager;
import oct.codegen.taskManager;
import oct.codegen.user;
import oct.codegen.userManager;
import oct.pmp.exception.PmpException;
import oct.pst.PstAbstractObject;
import oct.pst.PstGuest;
import oct.pst.PstManager;
import oct.pst.PstUserAbstractObject;

import org.apache.log4j.Logger;
import org.apache.lucene.analysis.Analyzer;
import org.apache.lucene.analysis.TokenStream;
import org.apache.lucene.document.Document;
import org.apache.lucene.index.IndexReader;
import org.apache.lucene.search.TopDocs;
import org.apache.lucene.search.highlight.Highlighter;

import util.PrmLog;
import util.StringUtil;
import util.TaskInfo;
import util.Util;
import util.Util2;

public class QueryManagement {
	PstUserAbstractObject pstuser;
	static final SimpleDateFormat DF = new SimpleDateFormat("MM/dd/yy");
	static final SimpleDateFormat DBDF = new SimpleDateFormat("yyyy.MM.dd");
	static final SimpleDateFormat DBDFT = new SimpleDateFormat("yyyy.MM.dd.HH.mm.ss");
	static final String indexDir = Util.getPropKey(SEConstants.PST, SEConstants.SE_INDEX_PATH);
	static attachmentManager attMgr = null;
	static projectManager pjMgr = null;
	static userManager uMgr = null;
	static resultManager rMgr = null;
	static bugManager bMgr = null;
	static taskManager tkMgr = null;
	static planTaskManager ptkMgr = null;
	static actionManager aMgr = null;
	static meetingManager mMgr = null;
	
	static String multiCorp = Util.getPropKey("pst", "MULTICORPORATE");
	static boolean isMultiCorp = (multiCorp.equals("true"));
	
	static Logger l = PrmLog.getLog();
	
	private static final String CFNF = "Cache file not found";
	static {
		try {
			attMgr = attachmentManager.getInstance();
			pjMgr = projectManager.getInstance();
			uMgr = userManager.getInstance();
			rMgr = resultManager.getInstance();
			bMgr = bugManager.getInstance();
			tkMgr = taskManager.getInstance();
			ptkMgr = planTaskManager.getInstance();
			aMgr = actionManager.getInstance();
			mMgr = meetingManager.getInstance();
		}
		catch (PmpException e){}
	}
	
	public QueryManagement() {
		pstuser = null;
		if (multiCorp == null) multiCorp = "false";
	}
	
	public QueryManagement(PstUserAbstractObject pstuser) {
		this();
		this.pstuser = pstuser;
	}
	
	/**
	 * Goes through DB and checks to see which new 
	 * query needs to be executed. Calls mail handler 
	 * to generate an email.
	 * @return
	 */
	public static boolean activeQuery(PstUserAbstractObject pstuser) {
		try {
			Date now = new Date();
			Date today = DF.parse(DF.format(now));
			
			queryManager queryMgr = queryManager.getInstance();
			// Get all query that has not expired		
			int [] intArr = queryMgr.findId(pstuser, "ExpireDate>='"+DBDF.format(today)+"'");
			PstAbstractObject [] objArr = queryMgr.get(pstuser, intArr);
			// Run each query
			for (int i=0; i<objArr.length; i++) {
				query qry = (query)objArr[i];
				Object obj = qry.getAttribute("Frequency")[0];
				int frequency = (obj!=null)?Integer.parseInt(obj.toString()):-1;
				int catInt = 0;
				obj = qry.getAttribute("Category")[0];
				String category = (obj!=null)?obj.toString():null;
				if (category.equalsIgnoreCase(query.CAT_BLOG))
					catInt = 1;
				else if (category.equalsIgnoreCase(query.CAT_MINUTE))
					catInt = 2;
				
				
				obj = qry.getAttribute("LastExecuteDate")[0];
				Date lastExecuteDate = (obj!=null)?(Date)obj:null;			
				obj = qry.getAttribute("Expr")[0];
				String query = (obj!=null)?extractQuery(obj.toString()):null;
				String filter = (obj!=null)?extractFilter(obj.toString(), DBDFT.format(lastExecuteDate), catInt):null;
				obj = qry.getAttribute("Owner")[0];
				String ownerId = (obj!=null)?obj.toString():null;
				obj = qry.getAttribute("Name")[0];
				String name = (obj!=null)?obj.toString():"";
				obj = qry.getAttribute("Description")[0];
				String description = (obj!=null)?new String((byte[])obj):"";

				if (isTimeToExecute(frequency))	{
					SearchResult sr = null;
					FilteredResult fr = null;
					if (catInt == 0) {
						sr = SearchIndex.getSearchResults(query);
						QueryManagement qm = new QueryManagement(pstuser);
						fr = qm.mergeData(sr, filter);
					}
					// email results function

					emailResults(sr, fr, query, filter, catInt, pstuser, ownerId, name, description);
					
					// update query object
					qry.setAttribute("LastExecuteDate", now);
					qry.setAttribute("LastUpdatedDate", now);
					queryMgr.commit(qry);
				}
			}
		} catch (ParseException e) {
			l.error(e);
 		} catch (PmpException e) {
			l.error(e);
		}
		return false;
	}	
	
	/**
	 * Fetches the contents from cached files
	 * @param sr
	 * @param fr
	 * @param idx
	 * @return
	 */
	public static String fetchContents(SearchResult sr, FilteredResult fr, int idx, PstUserAbstractObject pstuser) {
		try {
			if (sr != null) {
				List <Document> listDoc = fr.getListDoc();
				Highlighter highlighter = sr.getHighlighter();
				Document doc = (Document)listDoc.get(idx);
				return fetchContents(doc, highlighter);
			}
			// no query specified
			else {
				try {
					if (attMgr == null)
						attMgr = attachmentManager.getInstance();
					int [] intArr = fr.getIntArr();
					PstAbstractObject pstObj = attMgr.get(pstuser, intArr[idx]);
					Object obj = pstObj.getAttribute(attachment.LOCATION)[0];
					String fileLocation = (obj!=null)?obj.toString():"";
					String path = mod.se.Util.createCachePath(fileLocation);
					return fetchContents(path, null);
				} catch (PmpException e) {
					l.error(e);
					return CFNF;
				}
			}
		} catch (Exception e) {
			l.error(e);
			return CFNF;
		}
	}
	
	public static String fetchContents(Document doc, Highlighter highlighter) {
		try {
			String fileLocation = doc.get(SEConstants.PATH);
			String path = mod.se.Util.createCachePath(fileLocation);
			return fetchContents(path, highlighter);
		} catch (Exception e) {
			l.error(e);
			return CFNF;
		}
	}
	
	public static String fetchContents(String path, Highlighter highlighter) {
		try {
			StringBuffer sb = new StringBuffer(4096);
			String contents = null;
			String highlighted = null;
			// Fetch cache file information
			if (path != null && path.length() > 0) {
				BufferedReader in = new BufferedReader(new FileReader(new File(path)));
				String str;
				while ((str = in.readLine()) != null) {
					sb.append(str);
				}
				in.close();
				contents = Util.stringToHTMLString(sb.toString());
			}
			// Mark highlights
			if (contents != null && contents.length() > 0 && highlighter != null) {
				IndexStatus.setCurrentlyUsed(true);
				Analyzer analyzer = SearchIndex.getAnalyzer();
				TokenStream tokenStream =
						analyzer.tokenStream(SEConstants.CONTENTS, new StringReader(contents));
				highlighted = highlighter.getBestFragments(tokenStream, contents, 3, " ... ");
				tokenStream.close();
				IndexStatus.setCurrentlyUsed(false);
				return highlighted;
			} 
			// No highlighter, display first 200 characters (user provided only filters)
			else if (contents != null && contents.length() > 0) {
				int length = contents.length();
				if (length > 200)
					contents = contents.substring(0, 200);

				// create a space to correct alignment
				StringBuffer temp = new StringBuffer(200);
				int count = 0;
				for (int i=0; i<contents.length(); i++) {
					char character = contents.charAt(i);
					if (character != ' ') {
						count++;
						if (count == 65) {
							temp.append(' ');
							count = 0;
						}
					}
					else
						count = 0;
					temp.append(character);
				}
				contents = temp.toString();
System.out.println("okF");
				
				return contents;
			} else
				return CFNF;
		} catch (IOException e) {
			l.error(e);
			return CFNF;
		} catch (Exception e) {
			l.error(e);
			return CFNF;
		}
	}
	
	public static String fetchFilePath(SearchResult sr, FilteredResult fr, int idx, PstUserAbstractObject pstuser) {
		String fileLocation = null;
		try {
			if (attMgr == null)
				attMgr = attachmentManager.getInstance();
			int [] intArr = fr.getIntArr();
			PstAbstractObject pstObj = attMgr.get(pstuser, intArr[idx]);
			Object obj = pstObj.getAttribute(attachment.LOCATION)[0];
			fileLocation = (obj!=null)?obj.toString().trim().substring(2):"";
		} catch (PmpException e) {
			l.error(e);
		}
		return fileLocation;
	}
	
	public static String fetchFilePath(SearchResult sr, FilteredResult fr, int idx) {
		String fileLocation = null;
		if (sr != null) {
			List <Document> listDoc = fr.getListDoc();
			Document doc = (Document)listDoc.get(idx);
			fileLocation = doc.get(SEConstants.PATH).substring(2);
		}
		return fileLocation;
	}
	
	public static String fetchFileName(String zippedFilePath) {
		if (zippedFilePath != null) {
			int forwardIdx = zippedFilePath.lastIndexOf("/");
	    	int backwardIdx = zippedFilePath.lastIndexOf("\\");
	    	int pathIdx = (forwardIdx>backwardIdx)?forwardIdx:backwardIdx;
			return (pathIdx != -1 && zippedFilePath.length() > pathIdx+1)?zippedFilePath.substring(pathIdx+1):null;
		}
		return null;
	}
	
	/**
	 * Fetches information that matches with the filters 
	 * and merges the id against the Hit results. Returns 
	 * an array of id. Reconstructs the Hit h with the only 
	 * the filtered information.
	 * @param query
	 * @param filter
	 * @return
	 */
	public FilteredResult mergeData(SearchResult sr, String filter) {	
		try {			
			List <Document> listDoc = new ArrayList<Document>();
			List <Integer> listInt = new ArrayList<Integer>();
			int[] intArr = new int[0];
			TopDocs hits = null;
			Document doc;
			String idS;
			int attid, idx;
			Integer iObj;
			ArrayList <Integer> obj;
			ArrayList <Integer> arrList;

			IndexReader reader = SearchIndex.getReader();

			if (sr != null)
				hits = sr.getHits();
			
			if (attMgr == null)
				attMgr = attachmentManager.getInstance();
				if (!StringUtil.isNullOrEmptyString(filter))
				{
					System.out.println("QM.mergeData() on filter: " + filter);
					int[] attIdArr = attMgr.findId(pstuser, filter);

					if (hits != null)
					{
						// map of attId, index_in_hits
						Map <Integer, ArrayList<Integer>>map = new HashMap <Integer, ArrayList<Integer>> ();
						
						// this loop will eliminate repeat documents in the hits
						for (int i=0; i<hits.totalHits; i++) {
							doc = reader.document(hits.scoreDocs[i].doc);
							idS = doc.get(SEConstants.ID);
							iObj = new Integer(idS);
							obj = map.get(iObj);
							
							if (obj == null) 
								arrList = new ArrayList<Integer>();
							else 
								arrList = obj;
							arrList.add(new Integer(i));
							
							map.put(iObj, arrList);
						}
					
						for (int i=0; i<attIdArr.length; i++) {
							attid = attIdArr[i];
							Integer idI = Integer.valueOf(attid);				
							if (map.containsKey(idI)) {
								arrList = map.get(idI);
								for (int j=0; j<arrList.size(); j++) {
									idx = ((Integer)arrList.get(j)).intValue();
									doc = reader.document(hits.scoreDocs[idx].doc);
									listDoc.add(doc);
									listInt.add(idI);									
								}
							}
						}
					}
					else
					{
						// no hits from search, just return the attachments passed in
						for (int i=0; i<attIdArr.length; i++) {
							attid = attIdArr[i];
							listInt.add(new Integer(attid));
						}
					}
				}
				else
				{
					// No expression filter and single company, place all results into list
					if (hits != null)
					{
						for (int i=0; i<hits.totalHits; i++) {
							doc = reader.document(hits.scoreDocs[i].doc);
							attid = Integer.parseInt(doc.get(SEConstants.ID));
							listDoc.add(doc);
							listInt.add(new Integer(attid));
						}
					}
				}
				
				// @AGQ091506
				// Filter all acceptable files
				filterAccessDenied(listDoc, listInt);

				intArr = new int[listInt.size()];	
				for (int i=0; i<intArr.length; i++) {
					iObj = (Integer)listInt.get(i);
					if (iObj != null)
						intArr[i] = iObj.intValue();
					else {
						intArr[i] = -1;
						l.error("Index contains null ID");
					}

			}			
			return new FilteredResult(listDoc, intArr);
		} catch (NumberFormatException e) {
			l.error(e);
		} catch (IOException e) {
			l.error(e);
		} catch (PmpException e) {
			l.error(e);
		}
		return null;
	}

	/**
	 * Loops through all accepted results and filters out the files again.
	 * Grabs the attachment object and check if name is under TeamMembers
	 * attribute. Public meetings will not have a value in TeamMembers but
	 * private meeting will store accessible users id. 
	 * Second if the file is still acceptable checks to see if the file
	 * is part of the town. (This process is much heavier and will not run
	 * if multiCorp == false.
	 * @param listDoc The listDoc from search result
	 * @param listInt The attachment object ids
	 * @throws PmpException
	 */
	private void filterAccessDenied(List <Document> listDoc, List <Integer> listInt) throws PmpException {
		// Check each listDoc for removal 
		// 1. Not part of the private meeting
		// 2. Not part of the town
		// @071906ECC
/*		String townIdS = null;
		if (isMultiCorp) {
			objArr = pstuser.getAttribute("Towns"); // detect null in case of guest user
			if (objArr!=null && objArr[0]!=null) townIdS = ((Integer)objArr[0]).toString();
			// @ECC080108: for CR multicorp, we put Company into the user object to identify his company
			townIdS = pstuser.getStringAttribute("Company");
		}
*/	
		int length = listInt.size();
		int myUid = pstuser.getObjectId();
		boolean isAdmin = myUid<11000;
		attachment aObj = null;
		boolean canSee;
		String pidS, ownerIdS, s;
		System.out.println("+++ " + length + " files found checking in filterAccessDenied().");
		if (isAdmin) {
			System.out.println("    isAdmin: no filter denial.");
			return;
		}
		
		// filter by project membership
		int [] ids = pjMgr.getProjects(pstuser);
		String projIdListS = StringUtil.toString(ids, ";");

		
		// Loop through each listInt
		for (int i=length-1; i>=0; i--) {
			int aId = ((Integer) listInt.get(i)).intValue();
			try {aObj = (attachment) attMgr.get(pstuser, aId);}
			catch (Exception e) {l.error("Fail to get attachment [" + aId + "]"); continue;}
			//objArr = a.getAttribute(user.TEAMMEMBERS);	// ECC: attachment doesn't have TeamMembers attribute
			pidS = (String) aObj.getAttribute("ProjectID")[0];
			canSee = true;	//false;
			
			
			// @ECC031709 restrictive access
			// restrict by project team members
			if (!projIdListS.contains(pidS))
				canSee = false;			// not same project, can't see
			
			// TODO: need to check Restrictive Task

			
			// townIdS == null when multiCorp is false
			if (!canSee) {
				
				// not my town's project, but if I am owner or shared by me, then it's OK
				ownerIdS = (String)aObj.getAttribute("Owner")[0];				
				if (ownerIdS!=null && Integer.parseInt(ownerIdS)!=myUid)
				{
					// I am not owner but I might be in the ShareID
					s = Util2.getAttributeString(aObj, "ShareID", ";");
					if (s.contains(String.valueOf(myUid)))
						canSee = true;	// I am a shared member, let me see the file
				}
				else
					canSee = true;		// I am owner or doc has no owner
			}
			
			////////////////////////
			// Cannot find id, remove file
			if (!canSee) {
				try {
					listInt.remove(i);
					listDoc.remove(i);
				} catch (Exception e) {}
			}
			
		}	// END: for each file
	}
	
	private static String extractQuery(String expr) {
		// cut expr and query
		String query = null;
		if (expr != null) {
			String [] array = expr.split(PostSearch.DELIM);
			if (array.length > 0)
				query = array[0];
		}	
		return query;
	}
	
	private static String extractFilter(String expr, String now, int catInt) {
		// cut expr and filter
		StringBuffer sb = new StringBuffer();
		if (expr != null) {
			String [] array = expr.split(PostSearch.DELIM);
			if (array.length > 2 && array[2]!=null && array[2].trim().length()>0)
				sb.append(array[2]);
			if (now != null && now.trim().length() > 0) {
				String createdDate = "CreatedDate";
				if (sb.length() > 0)
					sb.append(" && ");
				if (catInt == 2) {
					createdDate = "StartDate";
				}
				sb.append(createdDate + ">='" + now + "'");
			}
		}
		return sb.toString();
	}
	
	private static void emailResults(SearchResult sr, FilteredResult fr, String query, String expr, int category, PstUserAbstractObject pstuser, String ownerId, String name, String description) {
		StringBuffer msgText = new StringBuffer();
		StringBuffer subject = new StringBuffer(30);
		String email = null;
		try {
			userManager userMgr = userManager.getInstance();
			int oid = Integer.parseInt(ownerId);
			user usr = (user)userMgr.get(pstuser, oid);
			Object obj = usr.getAttribute("Email")[0];
			email = (obj!=null)?obj.toString():null;
			//obj = usr.getAttribute("FirstName")[0];
			//String fname = (obj!=null)?obj.toString():null;
			//obj = usr.getAttribute("LastName")[0];
			//String lname = (obj!=null)?obj.toString():null;
						
			msgText.append(createHTML(category, sr, fr, query, expr, pstuser, name, description));
				
			subject.append("[" + Util.getPropKey("pst", "APPLICATION").toUpperCase());
			subject.append("] Active Query Result - ");
			subject.append(name);
			
		} catch (PmpException e) {
			l.error(e);
			return;
		}
		
		Object [] receipient = new Object [1];
		receipient[0] = email;
		if (msgText.length() > 0)
			Util.sendMailAsyn(pstuser, Util.getPropKey("pst", "ADMIN_EMAIL"), receipient, null, null, subject.toString(), msgText.toString(), "alert.htm");
	}
	
	private static boolean isTimeToExecute(int frequency) {
		Calendar rightNow = Calendar.getInstance();
		int hour = rightNow.get(Calendar.HOUR_OF_DAY);		
		// Hourly
		if (frequency == 0)
			return true;
		// 5am 12pm 5pm
		if ((hour == 5 || hour == 12 || hour == 17) && frequency == 1) {
			return true;
		}
		// 12am
		if (hour == 0 && frequency == 2)
			return true;
		
		return false;
	}	
	
	private static String createHTML(int iCategory, SearchResult sr, FilteredResult fr, String query, String expr, PstUserAbstractObject pstuser, String name, String description) {
		try {
			PstManager mgr = null;
			int [] resultIDs;
			
			if (iCategory == 1)
				mgr = resultManager.getInstance();
			else if (iCategory == 0)
				mgr = attachmentManager.getInstance();
			else
				mgr = meetingManager.getInstance();
		
			if (iCategory == 0)
			{
				if (fr != null && sr != null)
					resultIDs = fr.getIntArr();
				else
					resultIDs = mgr.findId(pstuser, expr);
			}
			else
				resultIDs = mgr.findId(pstuser, expr);
			return createHTML(resultIDs, mgr, query, expr,  iCategory, sr, fr, pstuser, name, description);
		} catch (PmpException e) {
			return null;
		}
		
	}
	
	private static String createHTML(int [] resultIDs, PstManager mgr, String keywords, String expr, int iCategory, SearchResult sr, FilteredResult fr, PstUserAbstractObject pstuser, String name, String description) {
		StringBuffer out = new StringBuffer(2000);
		    try {
			final int iCatFile = 0;
			final int iCatBlog = 1;
			final int iCatMin  = 2;

			if (pstuser instanceof PstGuest)
			{
				//response.sendRedirect("../out.jsp?e=Access declined");
				return null;
			}
			String s = null;

			String host = Util.getPropKey("pst", "PRM_HOST");
						
			String postDateTitle = null;
			Date dt;
			if (iCategory == iCatMin) postDateTitle = "StartDate";		// we will need this later also
			else postDateTitle = "CreatedDate";
			
			String postTitle = null;
//			 unfortunately the attribute names are not the same for different type of objects
			if (iCategory == iCatBlog) postTitle = "Creator";
			else if (iCategory == iCatFile) postTitle = "Owner";
			else postTitle = "Recorder";
			
			//////////////
			// keywords: use Java regex to filter
			
			expr = null; //get from parameter
			
			String matchKey = "";
			//String keywords = null;//request.getParameter("Keyword");
			if (keywords == null) keywords = "";
			if (keywords.length() > 0)
			{
				// OR together multiple keywords
//				bCheckPref = false;
				String delim = " ";
				if (keywords.indexOf(",") != -1)
					delim = ",";
				else if (keywords.indexOf(";") != -1)
					delim = ";";
				String [] sa = keywords.split(delim);

				for (int i=0; i<sa.length; i++)
				{
					// trim trailing spaces and remove trailing % and *
					s = sa[i].replaceAll("^[ \t%*]+|[\\\\]+|[ \t%*]+$", "");
					if (s.length() == 0) {			
						continue;
					}
					if (matchKey.length() > 0) matchKey += "|";
					matchKey += "(" + s + ")";
				}
			}
			
			Pattern p = Pattern.compile(matchKey, Pattern.CASE_INSENSITIVE);
			Matcher m = p.matcher("");

			// get the list of results

			int [] ids;
		    
			PstAbstractObject [] objArr = null;
			PstAbstractObject [] countObjArr = mgr.get(pstuser, resultIDs);

			// Handle problem with numbers of result
			if (iCategory == iCatBlog || iCategory == iCatMin) {
				String binary = null;
				if (iCategory == iCatBlog) {
					binary = "Comment";
				}
				else if (iCategory == iCatMin) {
					binary = "Note";
				}
				int newCount = 0;
				for (int i=0; i<countObjArr.length; i++) {
					PstAbstractObject pstObj = (PstAbstractObject)countObjArr[i];
					Object obj = pstObj.getAttribute(binary)[0];
					String text = (obj!=null)?new String((byte[])obj):"";
					
					if (matchKey.length() > 0)
					{
						String plainText = text.replaceAll("<\\S[^>]*>", "");
						m.reset(plainText);
						if (!m.find()) {
							countObjArr[i] = null;
							continue;
						}
					}
					newCount++;
				}
				
				objArr = new PstAbstractObject[newCount];
				int newCounter = 0;
				for (int i=0; i<countObjArr.length; i++) {
					if (newCount == newCounter)
						break;
					if (countObjArr[i] == null)
						continue;
					objArr[newCounter] = countObjArr[i];
					newCounter++;
				}
			}
			else
				objArr = countObjArr;
			
			if (iCategory != iCatFile)
				Util.sortDate(objArr, postDateTitle, true);
			
			String projName = "";

			String bText = "";
			Object bTextObj;
			PstAbstractObject obj, objType, projObj;
			int objId, idx, pTaskId=0;
			String type, nameStr, uname, lname, parentIdS;
			String idS=null, projIdS=null, bugIdS=null, gotoS=null, fname=null;
			String ADtypeStr = null, blogSummary = null, mSchedule1 = null, mSchedule2 = null;
			Object tempObj;
			user bUser;
			PstAbstractObject [] objTypeArr = null;
			SimpleDateFormat df1 = new SimpleDateFormat ("MM/dd/yy (EEEEE)");
			SimpleDateFormat df2 = new SimpleDateFormat ("hh:mm a");
			SimpleDateFormat df3 = new SimpleDateFormat ("MM/dd/yyyy hh:mm a");
			Date meetingDt1 = null, meetingDt2 = null;
			//int count = 0;
			String extension = null;
			String zippedFileName;
			String zippedFilePath;
			
			int totalNum;
			if (iCategory == iCatFile)
				totalNum = resultIDs.length;
			else	
				totalNum = objArr.length;
			
			if (totalNum == 0)	
				return "";
			out.append("<table border='0' cellpadding='0' cellspacing='0'>");
			out.append("<tr><td class='blog_small'>Query Name:</td><td width='5'>&nbsp;</td><td>"+name+"</td></tr>");
			out.append("<tr><td class='blog_small'>Description:</t><td width='5'>&nbsp;</td><td>"+description+"</td></tr>");
			out.append("</table>");
			out.append("<table>");
			out.append("<tr><td width='5'><img src='"+host+"/i/spacer.gif' width='5'></td></tr>");
			out.append("<tr><td bgcolor='#bbbbbb' height='1'><img src='"+host+"/i/spacer.gif' height='1' border='0'></td></tr>");
			for (int i=0; i<totalNum; i++)
			{	
				projName = blogSummary = mSchedule1 = mSchedule2 = "";
				gotoS = "";
				//count++;					/// no. of objects I have processed in this round
				uname = "";	
				zippedFileName = null;
				zippedFilePath = null;
				// File results contains an s
				if (iCategory == iCatFile)
					obj = mgr.get(pstuser, resultIDs[i]);
				else
					obj = objArr[i];
				tempObj = obj.getAttribute("ProjectID")[0];
				projIdS = (obj!=null)?(String)tempObj:"";
				parentIdS = null;
			

				// blog comments
				// ids.  For blog, ids is the assoc task or bug ID; for minute, it is the assoc meeting ID; for file...  
				type = "";
				nameStr = "";		
				if (iCategory == iCatBlog)
				{
					type = (String)obj.getAttribute("Type")[0];
					parentIdS = (String)obj.getAttribute("ParentID")[0];

					if (parentIdS == null)
						idS	= (String)obj.getAttribute("TaskID")[0];
					else
					{
						// this is a blog comment
						PstAbstractObject o = rMgr.get(pstuser, parentIdS);
						idS = (String)o.getAttribute("TaskID")[0];
					}
				}
				else if (iCategory == iCatMin)
				{
					idS	= String.valueOf(obj.getObjectId());
					tempObj = obj.getAttribute("ProjectID")[0];
					projIdS = (tempObj!=null)?tempObj.toString():"";
					projObj = pjMgr.get(pstuser, Integer.parseInt(projIdS));
					projName = projObj.getObjectName();
					tempObj = obj.getAttribute("Subject")[0];
					nameStr = (tempObj!=null)?tempObj.toString():"";
					nameStr = "<a class='listlink' href='"+host+"/meeting/mtg_view.jsp?mid=" + idS + "'>" + nameStr + "</a>";
					type = "Meeting";
					meetingDt1 = (Date)obj.getAttribute("StartDate")[0];
					mSchedule1 = df3.format(meetingDt1);
					meetingDt2 = (Date)obj.getAttribute("ExpireDate")[0];
					mSchedule2 = df3.format(meetingDt2);
					
				}
				else if (iCategory == iCatFile)
				{
					// need to get the associated object and type 				
					fname = ((attachment)obj).getFileName();
					type = (String)obj.getAttribute("Type")[0];		
					extension = (String)obj.getAttribute("FileExt")[0];
					if (type == null) {
						type = "";
						gotoS = "external file";					
					}
					// for files: get assoc object ID, if it's from blog, get f char of the blog 
					else if (type.equals(attachment.TYPE_BUG) || type.equals(attachment.TYPE_B_BUG))
					{							
						if (projIdS != null && projIdS.trim().length() > 0) {
							projObj = pjMgr.get(pstuser, Integer.parseInt(projIdS));
							projName = projObj.getObjectName();
						}
						gotoS = "bug file";	
						int rId = -1;
						// Get blog's first 20 characters
						if (type.equals(attachment.TYPE_B_BUG)) {
							gotoS = "bug blog file";

							ids = rMgr.findId(pstuser, "AttachmentID='" + obj.getObjectId() + "'");
							objTypeArr = rMgr.get(pstuser, ids);
							Util.sortDate(objTypeArr, "CreatedDate", true);
							if (objTypeArr.length > 0) {
								objType = (result)objTypeArr[0];
								rId = objType.getObjectId();
								tempObj = objType.getAttribute("TaskID")[0];
								idS = (tempObj!=null)?tempObj.toString():idS; 
								tempObj = objType.getAttribute("Comment")[0];
								if (tempObj != null) 
								{
									blogSummary = new String((byte[])tempObj);
									blogSummary = blogSummary.replaceAll("<\\S[^>]*>", "");	
									if (blogSummary.length() > 300) blogSummary = blogSummary.substring(0,300);
									blogSummary = blogSummary.replaceAll("&nbsp;", " ");
									int len = blogSummary.length();
									if (len > 40) len = 40;
									blogSummary = blogSummary.substring(0,len);	
									blogSummary = blogSummary + "..." + 	
										"<a class='blog_small' href='"+host+"/blog/blog_task.jsp?projId=" + 
										projIdS + "&bugId=" + idS + "'> (more)</a>"; 
								}
							}
							else {
								System.out.println("idS: " + idS);
							}
							int [] bugIntArr = new int[1];
							try {
								Integer.parseInt(idS);
							} catch (Exception e) {
								System.out.println("Result: " + rId + " contains error information");
								continue;
							}
							bugIntArr[0] = Integer.parseInt(idS);
							objTypeArr = bMgr.get(pstuser, bugIntArr);
						}
						
						if (type.equals(attachment.TYPE_BUG)) {
							ids = bMgr.findId(pstuser, "AttachmentID='" + obj.getObjectId() + "'");
							objTypeArr = bMgr.get(pstuser, ids);
							
						}
						if (objTypeArr.length > 1) {
							System.out.println("AttachmentID: " + obj.getObjectId() + " is located in multiple objects");
						}
						// get Bug item
						for (int j=0; j<objTypeArr.length; j++)
						{
							objType = objTypeArr[j];
							idS	= String.valueOf(objType.getObjectId());
							nameStr	= (String)objType.getAttribute("Synopsis")[0];
							bugIdS = idS;
							nameStr = "<a class='listlink' href='"+host+"/bug/bug_update.jsp?bugId=" + bugIdS + "'>" + nameStr + "</a>";
						}	
					}
					else if (type.equals(attachment.TYPE_TASK) || type.equals(attachment.TYPE_B_TASK))
					{			
						ids = tkMgr.findId(pstuser, "AttachmentID='" + obj.getObjectId() + "'");
						objTypeArr = tkMgr.get(pstuser, ids);
						projObj = pjMgr.get(pstuser, Integer.parseInt(projIdS));
						projName = projObj.getObjectName();
						gotoS = "task file";
						if (objTypeArr.length > 0)
						{
							objType = objTypeArr[0];
							idS	= String.valueOf(objType.getObjectId());
							ids = ptkMgr.findId(pstuser, "TaskID='" + idS +"' && Status !='Deprecated'");
							if (ids.length <= 0) continue;
							Arrays.sort(ids);
							pTaskId = ids[ids.length-1];
							planTask ptk = (planTask)ptkMgr.get(pstuser, pTaskId);
							nameStr = TaskInfo.getTaskStack(pstuser, ptk);
							idx = nameStr.lastIndexOf(">>");
							if (idx > 0)
								nameStr = nameStr.substring(0, idx+2) + "<b>" + nameStr.substring(idx+2) + "</b>";
							else
								nameStr = "<b>" + nameStr + "</b>";
							nameStr = "<a class='listlink' href='"+host+"/project/task_update.jsp?projId="
									+projIdS+ "&pTaskId=" + ptk.getObjectId() + "'>" + nameStr + "</a>";
						}
						// Get blog's first 20 characters
						if (type.equals(attachment.TYPE_B_TASK)) 
						{
							gotoS = "task blog file";
							type = "Task";
							ids = rMgr.findId(pstuser, "AttachmentID='"+obj.getObjectId()+"'");
							// Found blog
							if (ids.length > 0) {
								objTypeArr = rMgr.get(pstuser, ids);
								objType = objTypeArr[0];
								// Get task id
								tempObj = objType.getAttribute("TaskID")[0];
								idS = (tempObj!=null)?tempObj.toString():"";
								// get Blog
								tempObj = objType.getAttribute("Comment")[0];
								if (tempObj != null) 
								{
									blogSummary = new String((byte[])tempObj);
									blogSummary = blogSummary.replaceAll("<\\S[^>]*>", "");	
									if (blogSummary.length() > 300) blogSummary = blogSummary.substring(0,300);
									blogSummary = blogSummary.replaceAll("&nbsp;", " ");
									int len = blogSummary.length();
									if (len > 40) len = 40;
									blogSummary = blogSummary.substring(0,len);	
									blogSummary = blogSummary + "..." + 	
										"<a class='blog_small' href='"+host+"/blog/blog_task.jsp?projId=" + 
										projIdS + "&taskId=" + idS + "'> (more)</a>"; 
								}
								// Get task name and link
								ids = ptkMgr.findId(pstuser, "TaskID='" + idS +"' && Status !='Deprecated'");
								if (ids.length <= 0) continue;
								Arrays.sort(ids);
								pTaskId = ids[ids.length-1];					
								planTask ptk = (planTask)ptkMgr.get(pstuser, pTaskId);
								nameStr = TaskInfo.getTaskStack(pstuser, ptk);
								idx = nameStr.lastIndexOf(">>");
								if (idx > 0)
									nameStr = nameStr.substring(0, idx+2) + "<b>" + nameStr.substring(idx+2) + "</b>";
								else
									nameStr = "<b>" + nameStr + "</b>";
								nameStr = "<a class='listlink' href='"+host+"/project/task_update.jsp?projId="
										+projIdS+ "&pTaskId=" + ptk.getObjectId() + "'>" + nameStr + "</a>";
							}
						}
					}
					else if (type.equals(attachment.TYPE_PROJECT))
					{		
						projObj = pjMgr.get(pstuser, Integer.parseInt(projIdS));
						projName = projObj.getObjectName();
						nameStr = "";
						gotoS = "project file";
					}
					else if (type.equals(attachment.TYPE_MEETING)) 
					{
						ids = mMgr.findId(pstuser, "AttachmentID='" + obj.getObjectId() + "'");
						objTypeArr = mMgr.get(pstuser, ids);
						if (objTypeArr.length > 0)
						{
							objType = (meeting)objTypeArr[0];
							tempObj = objType.getAttribute("ProjectID")[0];
							projIdS = (tempObj!=null)?tempObj.toString():"";
							if (projIdS != null && projIdS.length() > 0) {
								projObj = pjMgr.get(pstuser, Integer.parseInt(projIdS));
								projName = projObj.getObjectName();
							}
							nameStr = (String)objType.getAttribute("Subject")[0];
							nameStr = "<a class='listlink' href='"+host+"/meeting/mtg_view.jsp?mid=" + ids[0] + "'>" + nameStr + "</a>";
						}
						
						gotoS = "meeting file";
					}
					else if (type.equals(attachment.TYPE_B_ACTION)) 
					{
						projObj = pjMgr.get(pstuser, Integer.parseInt(projIdS));
						projName = projObj.getObjectName();
						ids = rMgr.findId(pstuser, "AttachmentID='" + obj.getObjectId() + "'");
						objTypeArr = rMgr.get(pstuser, ids);
						if (objTypeArr.length > 0)
						{
							// get result object
							objType = (result)objTypeArr[0];
							// get action id
							tempObj = objType.getAttribute("TaskID")[0];
							idS = (tempObj!=null)?tempObj.toString():"";
							// get blog
							tempObj = objType.getAttribute("Comment")[0];
							if (tempObj != null) 
							{
								blogSummary = new String((byte[])tempObj);
								blogSummary = blogSummary.replaceAll("<\\S[^>]*>", "");	
								if (blogSummary.length() > 300) blogSummary = blogSummary.substring(0,300);
								blogSummary = blogSummary.replaceAll("&nbsp;", " ");
								int len = blogSummary.length();
								if (len > 40) len = 40;
								blogSummary = blogSummary.substring(0,len);	
								
								blogSummary += "... " + 
									"<a class='blog_small' href='"+host+"/blog/blog_task.jsp?projId=" +
									projIdS + "&aid=" + idS + "'> (more)</a>";
							}
							
							objType = aMgr.get(pstuser, idS);
							tempObj = objType.getAttribute("Subject")[0];
							nameStr = (tempObj!=null)?tempObj.toString():"";
							if (nameStr.length() > 0)
								nameStr = "<a class='listlink' href='"+host+"/project/proj_action.jsp?projId=" +
									projIdS + "&aid=" + idS + "'>" + nameStr + "</a>";
						}
						
						gotoS = "action blog file";
					}
					gotoS = "(" + gotoS + ")";
				}
				else {
					// cannot find category display error
				}	
				// check object text (blog: comment; min: note; file: summary from SE)
				bText = "";
				if (iCategory == iCatFile)
				{
					if (type.equals("")) {
						zippedFilePath = QueryManagement.fetchFilePath(sr, fr, i, pstuser);
					}
					// get summary from SE
					if (extension != null && extension.equalsIgnoreCase("zip")) {
						String tempFileLocation = QueryManagement.fetchFilePath(sr, fr, i);
						zippedFileName = QueryManagement.fetchFileName(tempFileLocation);
						
					}
					bText = QueryManagement.fetchContents(sr, fr, i, pstuser);	
				}
				else
				{
					if (iCategory == iCatBlog)
						bTextObj = obj.getAttribute("Comment")[0];
					else
						bTextObj = obj.getAttribute("Note")[0];
					if (bTextObj != null)
						bText = new String((byte[])bTextObj);
				}
				objId = obj.getObjectId();
				dt		= (Date)obj.getAttribute(postDateTitle)[0];
				if (iCategory == iCatBlog)
				{
					if (type.equals(result.TYPE_BUG_BLOG))
					{
						tempObj = obj.getAttribute(postTitle)[0];
						s = (tempObj!=null)?tempObj.toString():null;
						if (s != null && s.length() > 0) {
							int userId = Integer.parseInt(s);
							bUser = (user)uMgr.get(pstuser, userId);
							lname = (String)bUser.getAttribute("LastName")[0];
							uname =  bUser.getAttribute("FirstName")[0] + " " + (lname==null?"":lname);
						}
						else
							uname = "USER NOT FOUND";	
						// bug blog
						obj = bMgr.get(pstuser, idS);
						tempObj = obj.getAttribute("ProjectID")[0];
						projIdS = (tempObj!=null)?tempObj.toString():null;
						if (projIdS != null && projIdS.length() > 0) {
							projObj = pjMgr.get(pstuser, Integer.parseInt(projIdS));
							projName = projObj.getObjectName();
						}
						nameStr	= (String)obj.getAttribute("Synopsis")[0];
						bugIdS = idS;
						nameStr = "<a class='listlink' href='"+host+"/bug/bug_update.jsp?bugId=" + bugIdS + "'>" + nameStr + "</a>";
						if (parentIdS == null)
							gotoS = "<a class='blog_small' href='"+host+"/blog/blog_task.jsp?projId=" + projIdS + "&bugId=" + bugIdS + "#" + objId + "'> GO TO BLOG</a>&nbsp;&nbsp;";
						else
						{
							nameStr += "<br>(Comment on Blog)";
							gotoS = "<a class='blog_small' href='"+host+"/blog/blog_comment.jsp?blogId=" + parentIdS
								+ "&projId=" + projIdS + "&id=" + idS
								+ "&blogNum=" + parentIdS + "&type=Bug'> GO TO COMMENT</a>&nbsp;&nbsp;";
						}
					}
					else if (type.equals(result.TYPE_TASK_BLOG))
					{
						tempObj = obj.getAttribute(postTitle)[0];
						s = (tempObj!=null)?tempObj.toString():null;
						if (s != null && s.length() > 0) {
							int userId = Integer.parseInt(s);
							bUser = (user)uMgr.get(pstuser, userId);
							lname = (String)bUser.getAttribute("LastName")[0];
							uname =  bUser.getAttribute("FirstName")[0] + " " + (lname==null?"":lname);
						}
						else
							uname = "USER NOT FOUND";
						// task blog
						obj = tkMgr.get(pstuser, idS);
						tempObj = obj.getAttribute("ProjectID")[0];
						projIdS = (tempObj!=null)?tempObj.toString():null;
						if (projIdS != null && projIdS.length() > 0) {
							projObj = pjMgr.get(pstuser, Integer.parseInt(projIdS));
							projName = projObj.getObjectName();
						}
					
						ids = ptkMgr.findId(pstuser, "TaskID='" + idS +"' && Status !='Deprecated'");
						if (ids.length <= 0) continue;
						Arrays.sort(ids);
						pTaskId = ids[ids.length-1];
						planTask ptk = (planTask)ptkMgr.get(pstuser, pTaskId);
						nameStr = TaskInfo.getTaskStack(pstuser, ptk);
						idx = nameStr.lastIndexOf(">>");
						if (idx > 0)
							nameStr = nameStr.substring(0, idx+2) + "<b>" + nameStr.substring(idx+2) + "</b>";
						else
							nameStr = "<b>" + nameStr + "</b>";
						nameStr = "<a class='listlink' href='"+host+"/project/task_update.jsp?projId="
								+projIdS+ "&pTaskId=" + ptk.getObjectId() + "'>" + nameStr + "</a>";
			
						bugIdS = "";
						if (parentIdS == null)
							gotoS = "<a class='blog_small' href='"+host+"/blog/blog_task.jsp?projId=" + projIdS + "&planTaskId=" + pTaskId + "#" + objId + "'> GO TO BLOG</a>&nbsp;&nbsp;";
						else
						{
							nameStr += "<br>(Comment on Blog)";
							gotoS = "<a class='blog_small' href='"+host+"/blog/blog_comment.jsp?blogId=" + parentIdS
								+ "&projId=" + projIdS + "&id=" + pTaskId
								+ "&blogNum=" + parentIdS + "&type=Task'> GO TO COMMENT</a>&nbsp;&nbsp;";
						}			
					}
					else if (type.equals(result.TYPE_ACTN_BLOG))
					{
						// action/decision blog
						tempObj = obj.getAttribute(postTitle)[0];
						s = (tempObj!=null)?tempObj.toString():null;
						if (s != null && s.length() > 0) {
							int userId = Integer.parseInt(s);
							bUser = (user)uMgr.get(pstuser, userId);
							lname = (String)bUser.getAttribute("LastName")[0];
							uname =  bUser.getAttribute("FirstName")[0] + " " + (lname==null?"":lname);
						}
						else
							uname = "USER NOT FOUND";
						obj = aMgr.get(pstuser, idS);
						tempObj = obj.getAttribute("ProjectID")[0];
						projIdS = (tempObj!=null)?tempObj.toString():null;
						if (projIdS != null && projIdS.length() > 0) {
							projObj = pjMgr.get(pstuser, Integer.parseInt(projIdS));
							projName = projObj.getObjectName();
						}
						
						nameStr	= (String)obj.getAttribute("Subject")[0];
						ADtypeStr = (String)obj.getAttribute("Type")[0];
			
						// use view meeting or project action/decision
						idS = (String)obj.getAttribute("MeetingID")[0];
						if (idS != null)
						{
							nameStr = "<a class='listlink' href='"+host+"/meeting/mtg_view.jsp?mid=" + idS
								+ "&aid=" + obj.getObjectId()+ "#action'>" + nameStr + "</a>";
						}
						else
						{
							nameStr = "<a class='listlink' href='"+host+"/project/proj_action.jsp?projId=" + projIdS
								+ "&aid=" +obj.getObjectId()+ "'>" + nameStr + "</a>";
						}
						if (parentIdS == null)
							gotoS = "<a class='blog_small' href='"+host+"/blog/blog_task.jsp?projId=" + projIdS + "&aId=" + obj.getObjectId() + "#" + objId + "'> GO TO BLOG</a>&nbsp;&nbsp;";
						else
						{
							nameStr += "<br>(Comment on Blog)";
							gotoS = "<a class='blog_small' href='"+host+"/blog/blog_comment.jsp?blogId=" + parentIdS
								+ "&projId=" + projIdS + "&id=" + obj.getObjectId()
								+ "&blogNum=" + parentIdS + "&type=Action'> GO TO COMMENT</a>&nbsp;&nbsp;";
						}			
					}
					else
					{
						// personal blog
						nameStr = "Engineering Logbook Entry";
						idS = "-";
						bugIdS = projIdS = "";
						gotoS = "<a class='blog_small' href='logbook.jsp?update=" + objId + "'> EDIT</a>&nbsp;&nbsp;";
					}
				}
				// check keywords
				if (matchKey.length() > 0)
				{
					String plainText = bText.replaceAll("<\\S[^>]*>", "");
					m.reset(plainText);
					if (!m.find()) 
					{
						if (iCategory != iCatFile)
							continue;
					}
				}
				// begin listing
				// partition line on top
				out.append("<tr><td width='1'><img src='"+host+"/i/spacer.gif' width='1' height='5'></td></tr>");


				// *** top portion table
				out.append("<tr height='100%'><td valign='top' height='100%'>");
				out.append("<table border='0' height='100%' width='750' cellspacing='0' cellpadding='0'><tr height='100%'>");

				/////// top left table contain Date and Blog Text
				out.append("<td width='500' valign='top' height='100%'>");
				out.append("<table width='100%' height='100%' border='0' cellspacing='0' cellpadding='0'>");

				// posted date
				//out.append("<tr><td width='1'><img src='"+host+"/i/spacer.gif' width='1' height='15'></td></tr>");
				if (iCategory == iCatBlog)
				{
					out.append("<tr><td class='blog_date' valign='top' align='left'>");
					if (dt != null)
						out.append(df1.format(dt));
					else
						out.append("-");
					out.append("</td></tr>");
				}
				else if (iCategory == iCatMin)
					out.append("<tr><td class='blog_date' valign='top' align='left'><b>Meeting Minutes</b></td></tr>");
				else
				{
					out.append("<tr><td class='blog_date' valign='top' align='left'><b>");
					out.append("<a class='listlink' href='" + host + "/servlet/ShowFile?attId=" + obj.getObjectId()+"'>" + fname);
					if (zippedFileName != null && zippedFileName.length() > 0) {
						out.append(" - " + zippedFileName); 	
					}
					out.append("</a>");
					out.append("</b></td></tr>");
				}
				out.append("<tr><td height='10'><img src='"+host+"/i/spacer.gif' width='1' height='10'></td></tr>");
				// display blog

				
				if (iCategory != iCatBlog) {
					tempObj = obj.getAttribute(postTitle)[0];
					s = (tempObj!=null)?tempObj.toString():null;
					if (s != null && s.length() > 0) {
						try {
							int userId = Integer.parseInt(s);
							bUser = (user)uMgr.get(pstuser, userId);
							lname = (String)bUser.getAttribute("LastName")[0];
							uname =  bUser.getAttribute("FirstName")[0] + " " + (lname==null?"":lname);
						} catch (PmpException e) {
							uname = "USER NOT FOUND";
						}
					}
					else {
						uname = "SYSTEM";
					}
				}
				out.append("<tr><td class='blog_text' valign='top'>");
				out.append(bText);
				out.append("<p></p></td></tr>");
				out.append("<tr height='100%'><td width='1' height='100%'><table border='0' width='100%' height='100%' cellspacing='0' cellpadding='0'><tr><td><img src='"+host+"/i/spacer.gif' width='1' height='5'></td></tr></table></td></tr>");

				// posted by
				out.append("<tr height='100%'><td valign='bottom'>");
				out.append("<table border='0' width='100%' height='50' cellspacing='0' cellpadding='0'>");
				out.append("<tr><td class='blog_by' valign='bottom' height='100%'>POSTED BY " + uname.toUpperCase() + " | ");
				if (iCategory == iCatBlog)
					out.append("<font color='#dd8833'>" + df2.format(dt) + "</font></td>");
				else
					out.append("<font color='#dd8833'>" + df3.format(dt) + "</font></td>");
				// goto blog
				out.append("<td class='plaintext' align='right' valign='bottom'>");
				out.append(gotoS);
				out.append("</td></tr></table></td></tr>");
				
				out.append("</table></td>");
				///// End top left table

				///// middle partition line
				out.append("<td width='5'><img src='"+host+"/i/spacer.gif' width='5'></td>");
				out.append("<td width='1' class='headlinerule'>");
				out.append("<table border='0' cellspacing='0' cellpadding='0' class='headlinerule'>");
				out.append("<tr><td><img src='"+host+"/i/spacer.gif' height='100%' width='1' alt=' ' /></td></tr>");
				out.append("</table></td>");

				///// top right table contain context and path
				out.append("<td width='10'>&nbsp;</td>");
				out.append("<td valign='top' width='200'>");
				out.append("<table width='100%' border='0' cellspacing='0' cellpadding='0'>");
				if (!type.equals(result.TYPE_ENGR_BLOG))
				{
					if (zippedFilePath != null && (projIdS == null || projName.length() == 0)) {
						out.append("<tr><td colspan='2' class='blog_small' valign='top'>Network Drive:</td></tr>");
						out.append("<tr><td>&nbsp;&nbsp;&nbsp;</td><td width='100%' align='left' class='blog_text'>" + zippedFilePath.replaceAll("/", " / ") + "</td></tr>");
					}
					else {
						out.append("<tr><td width='55' class='blog_small' valign='top'>Project:</td>");
						if (projIdS != null && projName.length() > 0)
						{
							// display project name and link
							projName = "<a class='listlink' href='"+host+"/project/proj_plan.jsp?projName=" + projName + "'>" + projName + "</a>";	// use projId
							out.append("<td valign='top'>" + projName + "</td></tr>");
						}
						else
						{
							out.append("<td class='plaintext_grey' valign='top'>not specified</td></tr>");
						}			
					}
					if (nameStr.length() >0)
					{
						// display task name and link
						out.append("<tr><td width='55' class='blog_small' valign='top'>");
						if (type.equals(result.TYPE_ACTN_BLOG))
							out.append(ADtypeStr);
						else
							out.append(type.substring(0,1).toUpperCase() + type.substring(1));
						out.append(":</td><td width='195' class='plaintext_grey' valign='top'>" + nameStr + "</td></tr>");
					}
					
				}
				else
				{
					if (nameStr.length() >0)
						out.append("<tr><td width='195' class='blog_small' valign='top'>" + nameStr + "</td></tr>");
				}
				
				if (blogSummary.length() > 0) 
				{
					out.append("<tr><td width='55' class='blog_small' valign='top'>Blog:</td>");
					out.append("<td width='195' class='blog_text' valign='top'>" + blogSummary + "</td></tr>");
				}		
				if (mSchedule1.trim().length() > 0 && mSchedule2.trim().length() > 0)
				{
					out.append("<tr><td width='55' class='blog_small' valign='top'><b>Schedule: </b></td>");
					
		      out.append("\r\n");
		      out.append("\t\t\t<td width='195' class='blog_text' valign='top'>&nbsp;\r\n");
		      out.append("\t\t\t<script language=\"JavaScript\">\r\n");
		      out.append("//\t\t\t<!-- Begin\r\n");
		      out.append("\t\t\t\tvar diff = getDiffUTC();\r\n");
		      out.append("\t\t\t\tvar stD = new Date('");
		      out.append(mSchedule1);
		      out.append("');\r\n");
		      out.append("\t\t\t\tvar enD = new Date('");
		      out.append(mSchedule2);
		      out.append("');\r\n");
		      out.append("\t\t\t\tvar tm = stD.getTime() + diff;\r\n");
		      out.append("\t\t\t\tstD = new Date(tm);\r\n");
		      out.append("\r\n");
		      out.append("\t\t\t\ttm = enD.getTime() + diff;\r\n");
		      out.append("\t\t\t\tenD = new Date(tm);\r\n");
		      out.append("\r\n");
		      out.append("\t\t\t\tdocument.write(formatDate(stD, \"MM/dd/yy (E) hh:mm a\")\r\n");
		      out.append("\t\t\t\t\t+ \" - \" + formatDate(enD, \"hh:mm a\"));\r\n");
		      out.append("//\t\t\t End -->\r\n");
		      out.append("\t\t\t</script>\r\n");
		      out.append("\t\t\t</td></tr>\r\n");
		 		}
				out.append("<tr><td height='10'><img src='"+host+"/i/spacer.gif' width='1' height='10'></td></tr>");
				out.append("</table></td>");
				///// End top right table

				out.append("</tr></table></td></tr>");
				// *** close the top portion table

				// bottom portion

				// partition at the end
				out.append("<tr><td width='5'><img src='"+host+"/i/spacer.gif' width='5'></td></tr>");
				out.append("<tr><td bgcolor='#bbbbbb' height='1'><img src='"+host+"/i/spacer.gif' height='1' border='0'></td></tr>");
			}

				out.append("</table>");
			
		    } catch (Throwable t) {
		     
		    } finally {
		     
		    }
		  
		return out.toString();
	}
}
