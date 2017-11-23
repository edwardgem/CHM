package util;
//
//	Copyright (c) 2006 EGI Technologies.  All rights reserved.
//
/////////////////////////////////////////////////////////////////////
// $Header: /cvsrepo/PRM/WEB-INF/classes/util/PrmMtgConstants.java,v 1.20 2007/12/19 02:08:58 edwardc Exp $
//
//	File:	$RCSfile: PrmMtgConstants.java,v $
//	Author:	Allen G Quan
//	Date:	$Date: 2007/12/19 02:08:58 $
//  Description:
//      Constants used with Mtg
//
//  Required:
//
//	Optional:
//
//	Modification:
//		@AGQ101106	Counter for forcing update of mtg notes
/////////////////////////////////////////////////////////////////////

public interface PrmMtgConstants {
	public static final String HOSTS = Util.getPropKey("pst", "PRM_HOST");
	public static final int VAR_LENGTH = 4095;

	// DB's & URL's Attributes
	public static final String DRAFT = "Draft";
	public static final String NOTE = "Note";

	public static final String MID = "mid";
	public static final String PSTUSER = "pstuser";
	//public static final String LASTUPDATEDDATE = "LastUpdatedDate";
	public static final String DATE = "date";
	public static final String BTEXT = "bText"; // parameter for MeetingNotes
	public static final String ATTACHMENTID = "AttachmentID";
	public static final String SAVETO = "saveTo"; // parameter for location to save mtg notes (Draft, or Note)
	public static final String DEBUG = "debug";
	public static final String ATTENDEE = "Attendee";
	public static final String RECORDER = "Recorder";
	public static final String NEWATTENDEE = "newAttendee";
	public static final String SAVE = "save";
	public static final String EXPRIDX = "exprIdx";
	public static final int MAX_WAIT_ON_QUEUE = 30;
	
	public static final String CHATIDX = "chatIdx";
	
	// DB's & URL's Attributes for GetNames.java
	public static final String PROJID = "projId";
	public static final String FIRSTNAME = "FirstName";
	public static final String LASTNAME = "LastName";

	// XML
	public static final String XML_CONTENT = "text/xml;charset=utf-8";
	public static final String XML_CACHECONTROL = "Cache-Control";
	public static final String XML_NOCACHE = "no-cache";
	public static final String XML_RESPONSE_OP = "<response>\n";
	public static final String XML_RESPONSE_CL = "</response>";
	public static final String MEETINGNOTES = "meetingNotes";
	public static final String TIME = "time";
	public static final String LASTUPDATE = "lastUpdate";
	public static final String COUNTS = "counts";
	public static final String AIOBJTABLE = "aiObjTable";
	public static final String DSOBJTABLE = "dsObjTable";
	public static final String BGOBJTABLE = "bgObjTable";
	public static final String ATOBJTABLE = "atObjTable";
	public static final String ADOBJTABLE = "adObjTable";
	public static final String ONLINESTR  = "totalOnline";
	public static final String EXPRSTRING = "exprString";
	public static final String IQSTRING	= "inputQString";
	public static final String ALERTMESSAGE = "alertMessage";
	public static final String URL = "url";
	
	public static final String BRACKETOPL = "\t<";
	public static final String BRACKETOPR = ">";
	public static final String BRACKETCLL = "</";
	public static final String BRACKETCLR = ">\n";
	// RC; Recorder
	public static final String XML_RCNAMETEXT_OP = "<rcNameText>";
	public static final String XML_RCNAMETEXT_CL = "</rcNameText>\n";
	public static final String XML_RCNAMEVALUE_OP = "<rcNameValue>";
	public static final String XML_RCNAMEVALUE_CL = "</rcNameValue>\n";
	public static final String XML_RCEMPTY = "<rcNameTextEmpty>1</rcNameTextEmpty>";
	public static final String XML_RCSELECTED_OP = "<rcNameTextSelected>";
	public static final String XML_RCSELECTED_CL = "</rcNameTextSelected>";
	// XML for GetNames.java
	// RS; Responsible
	public static final String XML_RSNAMEVALUE_OP = "<rsNameValue>";
	public static final String XML_RSNAMEVALUE_CL = "</rsNameValue>\n";
	public static final String XML_RSNAMETEXT_OP = "<rsNameText>";
	public static final String XML_RSNAMETEXT_CL = "</rsNameText>\n";
	public static final String XML_RSEMPTY = "<rsNameTextEmpty>1</rsNameTextEmpty>";
	public static final String XML_RSSELECTED_OP = "<rsNameTextSelected>";
	public static final String XML_RESELECTED_CL = "</rsNameTextSelected>";
	// AD; Attendees
	public static final String XML_ADNAMETEXT_OP = "<adNameText>";
	public static final String XML_ADNAMETEXT_CL = "</adNameText>\n";
	public static final String XML_ADNAMEVALUE_OP = "<adNameValue>";
	public static final String XML_ADNAMEVALUE_CL = "</adNameValue>\n";
	public static final String XML_ADEMPTY = "<adNameTextEmpty>1</adNameTextEmpty>";
	// IB; Issues
	public static final String XML_IBNAMETEXT_OP = "<ibNameText>";
	public static final String XML_IBNAMETEXT_CL = "</ibNameText>\n";
	public static final String XML_IBEMPTY = "<ibNameTextEmpty>1</ibNameTextEmpty>";

	// Remove blank spaces including <p>, <br>, &nbsp, and \s
	public static final String REGEX = "((\\s)+(&(nbsp|NBSP);))+|^(<(p|P)[^>]*>((&(nbsp|NBSP);)|(\\s)|(<(br|BR)\\s?/?>)|( ))*</(p|P)>(\\s)*)+|(<(p|P)>((&(nbsp|NBSP);)|(\\s)|(<(br|BR)\\s?/?>))*</(p|P)>(\\s)*)+$|^((<(br|BR)\\s?/?>)|(&(nbsp|NBSP);)|\\s)+|((<(br|BR)\\s?/?>)|(&(nbsp|NBSP);)|\\s)+$";

	// Messages
	public static final String SAVEFAILED = "<span style='color: red; weight: bold'>Save Failed: </span>";
	public static final String NOUPDATES = "<span style='color: green;'>No Updates</span>";
	public static final String SAVED = "<span style='color: green'>Saved: </span>";
	public static final String USERTIMEOUT = "<span style='color: red;'>Session Timeout: Reload Page (F5)</span>";

	public static final String SESSIONTIMEOUT = HOSTS + "/out.jsp?e=Your session has Timeout.";
	public static final String NEWRECORDER = "You have been assigned to be the FACILITATOR.\n";
	
	//	 XXX: see javascript mtg.js if REVOKEDRECORDER line is edited
	public static final String REVOKEDRECORDER = "Your facilitator responsibility has been revoked.\n"; 
	public static final String ADJOURNED = "The meeting has been adjourned.\n";

	public static final String EMPTYSTRING = "";
	public static final String TEMPPRESENT = "present_";

	// Create AD Table
	public static final String ADDISABLE = " disabled";
	public static final String OPENTABLE = "<table border='0' cellspacing='0' cellpadding='0'>";
	public static final String CLOSETABLE = "</table>";
	public static final String OPENROW = "<tr>";
	public static final String CLOSEROW = "</tr>";

	public static final String ADTABLE01 = "<td valign='top' width='20'><input id='ckAD"; // + counterAD
	public static final String ADTABLE02 = "' type='checkbox' name='present_"; // + id
	public static final String ADTABLE03 = "'"; //+ UserEdit
	public static final String ADTABLECK = " checked";
	public static final String ADTABLE04 = "></td><td class='plaintext' width='115'><a href='../ep/ep1.jsp?uid="; // + id
	public static final String ADTABLE05 = "' class='listlink'>"; // + uname
	public static final String ADTABLE06 = "</a>";
	public static final String ADTABLE07 = "</td>";

	// Create AT Table
	public static final String ATTABLE01 = "<tr><td class='plaintext_grey'>None</td></tr>";
	public static final String ATTABLE02 = "<tr>\n";
	public static final String ATTABLE03 = "<td width='20' valign='top'><img src='../i/bullet_tri.gif' width='20' height='10'></td>";
	public static final String ATTABLE04 = "<td class='plaintext' width='320'>";
	public static final String ATTABLE05 = "<a class='listlink' href='" + HOSTS + "/servlet/ShowFile?filePath="; // + midS
	public static final String ATTABLE06 = "/Attachment-"; // + attmt
	public static final String ATTABLE07 = "'>"; // + attmt
	public static final String ATTABLE08 = "</a>";
	public static final String ATTABLE09 = "</td>";
	public static final String ATTABLE10 = "<td><input class='formtext' type='button' value='Delete'";
	public static final String ATTABLE11 = " onclick=\"javascript: ajaxDeleteAT(\'Attachment-"; // + attmt
	public static final String ATTABLE12 = "\');\" align=\"right\">";
	public static final String ATTABLE13 = "</td>";
	public static final String ATTABLE14 = "</tr>\n";
	public static final String ATTABLE15 = "</table>\n";


	// LastUpdatedDate with Counters @see PrmLiveMtg: getBit(int i);
	public static final int ARRAYSIZE = 8;

	public static final int ADINDEX = 0; // Attendee's and Recorder's List
	public static final int ATINDEX = 1; // Attachment
	public static final int MNINDEX = 2; // Meeting Notes
	public static final int AIINDEX = 3; // Action Item
	public static final int DCINDEX = 4; // Decision Records
	public static final int ISINDEX = 5; // Issues
	public static final int ININDEX = 6; // Input queue
	// @AGQ101106
	public static final int UDINDEX = 7; // Update full meeting notes

	public static final int ADBIT = 1; // Attendee and Recorder's Bit
	public static final int ATBIT = 2; // Attachment Bit
	public static final int MNBIT = 4; // Meeting Notes Bit
	public static final int AIBIT = 8; // Action Item Bit
	public static final int DCBIT = 16; // Decision Records Bit
	public static final int ISBIT = 32; // Issue Bit
	public static final int INBIT = 64; // Input queue Bit
	// @AGQ101106
	public static final int UDBIT = 128; // Update Full Meeting Notes Bit
	
	// Javascript variable names
	public static final String ADCOUNT = "ADCOUNT"; // Attendee and Recorder
	public static final String ATCOUNT = "ATCOUNT"; // Attachment
	public static final String MNCOUNT = "MNCOUNT"; // Meeting Notes
	public static final String AICOUNT = "AICOUNT"; // Action Item
	public static final String DCCOUNT = "DCCOUNT"; // Decision Records
	public static final String ISCOUNT = "ISCOUNT"; // Issue
	public static final String INCOUNT = "INCOUNT"; // Input queue
	// @AGQ101106	
	public static final String UDCOUNT = "UDCOUNT"; // Update Full Meeting Notes

	// jsp page label constants for mtg_live.jsp
	public static final String [] label0 = {"&nbsp;Action Item", "Responsible", "Pri.", "Blog", "Proj ID", "Issue", "Due", "Delete"};
	public static final int [] labelLen0 = {0, 100, 18, 30, 40, 40, 50, 35};

	public static final String [] label1 = {"&nbsp;Decision Record", "Pri.", "Blog", "Mtg ID", "Issue", "Filed On", "Delete"};
	public static final int [] labelLen1 = {0, 18, 30, 40, 40, 50, 35};

	// CR: jsp page label constants for mtg_live.jsp
	public static final String [] label0CR = {"&nbsp;Action Item", "Responsible", "Pri.", "Blog", "Proj ID", "Due", "Delete"};
	public static final int [] labelLen0CR = {0, 100, 18, 30, 40, 50, 35};

	public static final String [] label1CR = {"&nbsp;Decision Record", "Pri.", "Blog", "Mtg ID", "Filed On", "Delete"};
	public static final int [] labelLen1CR = {0, 18, 30, 40, 50, 35};

	// for OMF
	public static final String [] label1A = {"&nbsp;Decision Record", "Pri.", "Blog", "Mtg ID", "Filed On", "Delete"};
	public static final int [] labelLen1A = {0, 18, 30, 40, 50, 35};

	public static final String [] label2 = {"&nbsp;Issue", "Submitter", "Pri.", "Blog", "Proj ID", "My ID", "Filed On", "Delete"};
	public static final int [] labelLen2 = {0, 100, 18, 30, 40, 40, 50, 35};

	// jsp page label constants for mtg_live.jsp
	public static final String [] label0OMF = {"&nbsp;Action Item", "Responsible", "Pri.", "Blog", "Due", "Delete"};
	public static final int [] labelLen0OMF = {0, 100, 18, 30, 50, 35};

	public static final String [] label1OMF = {"&nbsp;Decision Record", "Pri.", "Blog", "Filed On", "Delete"};
	public static final int [] labelLen1OMF = {0, 18, 30, 50, 35};
	
	// PRM: jsp page label constants for mtg_view.jsp and mtg_update2.jsp
	public static final String [] vlabel0 = {"&nbsp;Action Item", "Responsible", "St.", "Pri.", "Blog", "Proj ID", "Issue", "Due", "Delete"};
	public static final int [] vlabelLen0 = {0, 100, 18, 18, 30, 40, 40, 50, 35};

	public static final String [] vlabel1 = {"&nbsp;Decision Record", "Pri.", "Blog", "Proj ID", "Issue", "Filed On", "Delete"};
	public static final int [] vlabelLen1 = {0, 18, 30, 40, 40, 50, 35};

	public static final String [] vlabel2 = {"&nbsp;Issue", "Submitter", "St.", "Pri.", "Blog", "Proj ID", "My ID", "Filed On", "Delete"};
	public static final int [] vlabelLen2 = {0, 100, 18, 18, 30, 40, 40, 50, 35};
	
	// OMF: jsp page label constants for mtg_view.jsp and mtg_update2.jsp OMF app
	public static final String [] vlabel0OMF = {"&nbsp;Action Item", "Responsible", "St.", "Pri.", "Blog", "Due", "Delete"};
	public static final int [] vlabelLen0OMF = {0, 100, 18, 18, 30, 50, 35};

	public static final String [] vlabel1OMF = {"&nbsp;Decision Record", "Pri.", "Blog", "Filed On", "Delete"};
	public static final int [] vlabelLen1OMF = {0, 18, 30, 50, 35};
	
	// CR: jsp page label constants for mtg_view.jsp and mtg_update2.jsp
	public static final String [] vlabel0CR = {"&nbsp;Action Item", "Responsible", "St.", "Pri.", "Blog", "Proj ID", "Due", "Delete"};
	public static final int [] vlabelLen0CR = {0, 100, 18, 18, 30, 40, 50, 35};

	public static final String [] vlabel1CR = {"&nbsp;Decision Record", "Pri.", "Blog", "Proj ID", "Filed On", "Delete"};
	public static final int [] vlabelLen1CR = {0, 18, 30, 40, 50, 35};
}
