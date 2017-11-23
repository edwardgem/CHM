////////////////////////////////////////////////////
//	Copyright (c) 2009, EGI Technologies, Inc.  All rights reserved.
//
//
//	File:	PrmGoogle.java
//	Author:	ECC
//	Date:	01/29/09
//	Description:
//		Implementation of PrmGoogle class.
//
//	Modification:
//
//
////////////////////////////////////////////////////////////////////

package util;

import java.io.File;
import java.io.IOException;
import java.io.PrintStream;
import java.net.MalformedURLException;
import java.net.URL;
import java.text.SimpleDateFormat;
import java.util.Date;
import java.util.TimeZone;
import java.util.logging.ConsoleHandler;
import java.util.logging.Level;
import java.util.logging.Logger;

import oct.codegen.day;
import oct.codegen.meeting;
import oct.codegen.quest;
import oct.codegen.userinfo;
import oct.pmp.exception.PmpException;
import oct.pst.PstAbstractObject;
import oct.pst.PstUserAbstractObject;

import com.google.gdata.client.Query;
import com.google.gdata.client.calendar.CalendarService;
import com.google.gdata.client.docs.DocsService;
import com.google.gdata.data.DateTime;
import com.google.gdata.data.PlainTextConstruct;
import com.google.gdata.data.acl.AclEntry;
import com.google.gdata.data.acl.AclRole;
import com.google.gdata.data.acl.AclScope;
import com.google.gdata.data.calendar.CalendarEventEntry;
import com.google.gdata.data.docs.DocumentEntry;
import com.google.gdata.data.docs.DocumentListEntry;
import com.google.gdata.data.docs.DocumentListFeed;
import com.google.gdata.data.extensions.When;
import com.google.gdata.util.AuthenticationException;
import com.google.gdata.util.ServiceException;

/**
 * @author edwardc
 *
 */
public class PrmGoogle
{
	public static final String DEF_FEED_HOST = "docs.google.com";
	public static final String XLS_FEED_HOST = "spreadsheets.google.com";
	private static final String FEED_URL_PATH = "/feeds/documents/private/full";
	
	public static final String CAL_FEED_HOST = "www.google.com/calendar";
	private static final String CAL_FEED_URL_PATH = "/feeds/default/private/full";
	
	private static final String DOCUMENT_CATEGORY = "/-/document";
	private static final String SPREADSHEET_CATEGORY = "/-/spreadsheet";
	private static final String PREFIX_DOC = "document%3A";
	private static final String PREFIX_PPT = "presentation%3A";
	private static final String PREFIX_XLS = "spreadsheet%3A";
	private static final String PREFIX_PDF = "pdf%3A";
	
	private static final String HOST = Util.getPropKey("pst", "PRM_HOST");
	
	private static org.apache.log4j.Logger l = PrmLog.getLog();

/** Our view of doclist service as an authenticated Google user. */
private DocsService service;
private CalendarService calService;
private String googleUid;

/** The URL of the doclist feed. */
private URL documentListFeedUrl;
private URL calendarListFeedUrl;

/** The output stream. */
private PrintStream out;

	public PrmGoogle(PstUserAbstractObject u)
		throws AuthenticationException, PmpException, MalformedURLException
	{
		this(new DocsService("CR"), System.out);

		// login to Google
		String [] sa = parseGoogleID(u);
		String uname = sa[0];
		String pass  = sa[1];
		loginDoc(uname, pass);
		documentListFeedUrl = new URL("http://" + DEF_FEED_HOST + FEED_URL_PATH);
	}
	
	public PrmGoogle(PstUserAbstractObject u, boolean isCalendar)
		throws AuthenticationException, PmpException, MalformedURLException
	{
		this(new CalendarService("CR"), System.out);

		// login to Google
		String [] sa = parseGoogleID(u);
		String uname = sa[0];
		String pass  = sa[1];
		loginCal(uname, pass);
		calendarListFeedUrl = new URL("http://" + CAL_FEED_HOST + CAL_FEED_URL_PATH);
	}

	  /**
	   * Constructs a document list demo from the specified document list service,
	   * which is used to authenticate to and access Google Documents.
	   *
	   * @param service the connection to the Google Documents service.
	   * @param outputStream a handle for stdout.
	   * @throws MalformedURLException if the URL for the docs feed is invalid.
	   */
	  public PrmGoogle(DocsService service, PrintStream outputStream)
	      throws MalformedURLException
	  {
	    this.service = service;
	    this.out = outputStream;
	  }
	  
	  public PrmGoogle(CalendarService service, PrintStream outputStream)
      throws MalformedURLException
      {
	    this.calService = service;
	    this.out = outputStream;
	  }
	  
	  private String [] parseGoogleID(PstUserAbstractObject u)
	  	throws PmpException, AuthenticationException
	  {
			String googleID = (String)u.getAttribute("GoogleID")[0];
			if (googleID == null)
				throw new AuthenticationException("Google ID not found in user profile.");
			String [] sa = googleID.split(":");		// uname:passwd
			if (sa.length != 2)
				throw new AuthenticationException("Google ID password not found in user profile.");
			return sa;
	  }

	  /**
	   * Log in to Google, under the Google Docs account.
	   *
	   * @param username name of user to authenticate (e.g. yourname@gmail.com)
	   * @param password password to use for authentication
	   * @throws AuthenticationException if the service is unable to validate the
	   *         username and password.
	   */
	  private void loginDoc(String username, String password)
	      throws AuthenticationException
	  {
	    // Authenticate
	    service.setUserCredentials(username, password);
	  }
	  
	  private void loginCal(String username, String password)
      throws AuthenticationException
      {
	    // Authenticate
	    calService.setUserCredentials(username, password);
	    googleUid = username;
      }

	  /**
	   * Prints out the specified document entry.
	   *
	   * @param doc the document entry to print
	   */
	  public void printDocumentEntry(DocumentListEntry doc) {
	    String shortId = doc.getId().substring(doc.getId().lastIndexOf('/') + 1);
	    out.println(
	        " -- Document(" + doc.getTitle().getPlainText() + "/" + shortId + ")");
	  }


	  /**
	   * Shows all documents that are in the documents list.
	   *
	   * @throws ServiceException when the request causes an error in the Google
	   *         Docs service.
	   * @throws IOException when an error occurs in communication with the Google
	   *         Docs service.
	   */
	  public void showAllDocs() throws IOException, ServiceException {
	    DocumentListFeed feed = service.getFeed(documentListFeedUrl,
	        DocumentListFeed.class);

	    out.println("List of all documents:");
	    for (DocumentListEntry entry : feed.getEntries()) {
	      printDocumentEntry(entry);
	    }
	  }
	  
	  public void listAllDocs() throws IOException, ServiceException {
		  DocumentListFeed feed = service.getFeed(documentListFeedUrl,
		        DocumentListFeed.class);

		String shortId;
		for (DocumentListEntry entry : feed.getEntries())
		{
		    shortId = entry.getId().substring(entry.getId().lastIndexOf('/') + 1);
		    out.println(
		        " -- Document(" + entry.getTitle().getPlainText() + "/" + shortId + ")");
		}
	  }
			  

	  /**
	   * Shows all word processing documents that are in the documents list.
	   *
	   * @throws ServiceException when the request causes an error in the Google
	   *         Docs service.
	   * @throws IOException when an error occurs in communication with the Google
	   *         Docs service.
	   */
	  public void showAllDocuments() throws IOException, ServiceException {
	    DocumentListFeed feed = service.getFeed(
	        new URL(documentListFeedUrl.toString() + DOCUMENT_CATEGORY),
	        DocumentListFeed.class);

	    out.println("List of all word documents:");
	    for (DocumentListEntry entry : feed.getEntries()) {
	      printDocumentEntry(entry);
	    }
	  }

	  /**
	   * Shows all wor processing documents that are in the documents list.
	   *
	   * @throws ServiceException when the request causes an error in the Google
	   *         Docs service.
	   * @throws IOException when an error occurs in communication with the Google
	   *         Docs service.
	   */
	  public void showAllSpreadsheets() throws IOException, ServiceException {
	    DocumentListFeed feed = service.getFeed(
	        new URL(documentListFeedUrl.toString() + SPREADSHEET_CATEGORY),
	        DocumentListFeed.class);

	    out.println("List of all spreadsheets:");
	    for (DocumentListEntry entry : feed.getEntries()) {
	      printDocumentEntry(entry);
	    }
	  }

	  /**
	   * Performs a full-text search on your documents.
	   *
	   * @param fullTextSearchString a full text search string, with space-separated
	   *        keywords
	   * @throws ServiceException when the request causes an error in the Doclist
	   *         service.
	   * @throws IOException when an error occurs in communication with the Doclis
	   *         service.
	   */
	  public void search(String fullTextSearchString)
	      throws IOException, ServiceException {
	    Query query = new Query(documentListFeedUrl);
	    query.setFullTextQuery(fullTextSearchString);
	    DocumentListFeed feed = service.query(query, DocumentListFeed.class);

	    out.println("Results for [" + fullTextSearchString + "]");

	    for (DocumentListEntry entry : feed.getEntries()) {
	      printDocumentEntry(entry);
	    }
	  }

	  /**
	   * Performs a full-text search on your documents.
	   *
	   * @param filePath path to uploaded file.
	   *
	   * @throws ServiceException when the request causes an error in the Doclist
	   *         service.
	   * @throws IOException when an error occurs in communication with the Doclist
	   *         service.
	   */
	  public String uploadFile(String filePath)
	      throws IOException, ServiceException {
	    DocumentEntry newDocument = new DocumentEntry();
	    File documentFile = new File(filePath);
		String fName = documentFile.getName();
	    String mimeType = fName.toLowerCase();
	    //String mimeType = new MimetypesFileTypeMap().getContentType(documentFile);
	    if (mimeType.endsWith(".doc"))
	    	mimeType = "application/msword";
	    else if (mimeType.endsWith(".xls"))
	    	mimeType = "application/vnd.ms-excel";
	    else if (mimeType.endsWith(".ppt"))
	    	mimeType = "application/vnd.ms-powerpoint";
	    else if (mimeType.endsWith(".pdf"))
	    	mimeType = "application/pdf";
	    else if (mimeType.endsWith(".html") || mimeType.endsWith(".htm"))
	    	mimeType = "text/html";
	    else
	    	mimeType = "text/plain";
	    newDocument.setFile(documentFile, mimeType);

	    // Set the title for the new document. For this example we just use the
	    // filename of the uploaded file.
	    newDocument.setTitle(new PlainTextConstruct(fName));
	    DocumentListEntry doc = null;
	    try {doc = service.insert(documentListFeedUrl, newDocument);}
	    catch (ServiceException e)
	    {
	    	// this might happen yet the upload is fine.  Goto Google to get the doc list and resolve the problem
	    	l.info("Got Google Data API Service Exception.");
	    	DocumentListFeed feed = service.getFeed(documentListFeedUrl,
	    	        DocumentListFeed.class);
	    	for (DocumentListEntry entry : feed.getEntries())
	    	{
	    		if (entry.getTitle().getPlainText().equals(fName))
	    		{
	    			doc = entry;
	    			break;
	    		}
	    	}
	    	if (doc == null)
	    	{
	    		l.error("CR tried everything to proceed but failed in uploading Google Docs.");
	    		throw new ServiceException("CR gave up uploading Google Docs.");
	    	}
	    }
	    printDocumentEntry(doc);
	    String shortId = doc.getId().substring(doc.getId().lastIndexOf('/') + 1);
	    String linkS = "", idS;
	    if (shortId.contains(PREFIX_DOC))
	    {
	    	idS = shortId.substring(PREFIX_DOC.length());
	    	// it used to be "/Doc?id="
	    	linkS = "http://" + DEF_FEED_HOST + "/document/edit?id=" + idS + "&hl=en";
	    }
	    else if (shortId.contains(PREFIX_PPT))
	    {
	    	idS = shortId.substring(PREFIX_PPT.length());
	    	linkS = "http://" + DEF_FEED_HOST + "/Presentation?docid=" + idS + "&hl=en";
	    }
	    else if (shortId.contains(PREFIX_XLS))
	    {
	    	// spreadsheet
	    	idS = shortId.substring(PREFIX_XLS.length());
	    	linkS = "http://" + XLS_FEED_HOST + "/ccc?key=" + idS + "&hl=en";
	    }
	    else if (shortId.contains(PREFIX_PDF))
	    {
	    	idS = shortId.substring(PREFIX_PDF.length());
	    	linkS = "http://" + DEF_FEED_HOST + "/fileview?id=F." + idS + "&hl=en";
	    }
	    else
	    {
	    	// text
	    }
	    return linkS;
	  }

	  @SuppressWarnings("unused")
	private static void turnOnLogging() {

	    // Configure the logging mechanisms
	    Logger httpLogger =
	        Logger.getLogger("com.google.gdata.client.http.HttpGDataRequest");
	    httpLogger.setLevel(Level.ALL);
	    Logger xmlLogger = Logger.getLogger("com.google.gdata.util.XmlParser");
	    xmlLogger.setLevel(Level.ALL);

	    // Create a log handler which prints all log events to the console
	    ConsoleHandler logHandler = new ConsoleHandler();
	    logHandler.setLevel(Level.ALL);
	    httpLogger.addHandler(logHandler);
	    xmlLogger.addHandler(logHandler);
	  }
	  
	  public void addACL(DocumentListEntry doc, String userEmail)
	  	throws IOException, ServiceException
	  {
		  AclEntry entry = new AclEntry();
		  entry.setScope(new AclScope(AclScope.Type.USER, userEmail));
		  entry.setRole(AclRole.WRITER);

		  URL aclUrl = new URL("http://" + doc.getId() + "/acl/full");
		  AclEntry insertedEntry = service.insert(aclUrl, entry);
	  }
	  
	  //////////////////////////////////////////////////////////////////
	  // Google Calendar
	  
	  // quickly add an event including OMF Event and Meeting
	  public void addEvent(PstAbstractObject qObj, TimeZone myTimeZone)
	  	throws Exception
	  {
			if (calService == null)
				throw new Exception("You must first connect to Google before adding event.");
			CalendarEventEntry myEntry = new CalendarEventEntry();

			/*
			WebContent wc = new WebContent();
			wc.setTitle((String)qObj.getAttribute("Subject")[0]);
			wc.setType("application/x-google-gadgets+xml");
			wc.setUrl(HOST + "/question/q_respond.jsp?qid=" + qObj.getObjectId());
			wc.setIcon(HOST + "/i/icon_face.gif");
			wc.setWidth("300");
			wc.setHeight("136");

			Map<String, String> prefs = new HashMap<String,String>();
			prefs.put("color", "green");
			wc.setGadgetPrefs(prefs);
			*/
			
			//myEntry.setWebContent(wc);
			
			// title
			String titleAttr;
			if (qObj instanceof day) {
				titleAttr = "Title";
			}
			else {
				titleAttr = "Subject";
			}
			myEntry.setTitle(new PlainTextConstruct(qObj.getStringAttribute(titleAttr)));

			// content
			String link = "";
			if (qObj instanceof quest) {
				// event
				link = HOST + "/question/q_respond.jsp?qid=";
			}
			else if (qObj instanceof meeting){
				// meeting
				link = HOST + "/meeting/mtg_view.jsp?mid=";
			}
			else {
				// day
				link = HOST + "/meeting/cal.jsp";
			}
			
			String desc = qObj.getRawAttributeAsString("Description");
			if (desc == null) desc = "";
			desc += "\n" + link + qObj.getObjectId();
			myEntry.setContent(new PlainTextConstruct(desc));
			
			// timezone
			SimpleDateFormat df = new SimpleDateFormat("yyyy-MM-dd'T'HH:mm:ss");
			if (myTimeZone!=null && !userinfo.isServerTimeZone(myTimeZone)) {
				df.setTimeZone(myTimeZone);
			}
			
			// time
			DateTime startTime, endTime;
			When eventTimes = new When();
			Date dt = (Date)qObj.getAttribute("StartDate")[0];
			if (dt != null) {
				startTime = DateTime.parseDateTime(df.format(dt));
				eventTimes.setStartTime(startTime);
			}
			dt = (Date)qObj.getAttribute("ExpireDate")[0];
			if (dt != null) {
				endTime = DateTime.parseDateTime(df.format(dt));
				eventTimes.setEndTime(endTime);
			}
			myEntry.addTime(eventTimes);

			//myEntry.setContent(new PlainTextConstruct(evtStr));
			//myEntry.setQuickAdd(true);
			//URL postUrl = new URL("http://" + CAL_FEED_HOST + CAL_FEED_URL_PATH);
			URL postUrl = new URL("https://" + CAL_FEED_HOST + "/feeds/" + googleUid + "/private/full");
			
			// Send the request and receive the response:
			CalendarEventEntry insertedEntry = calService.insert(postUrl, myEntry);
	  }
}
