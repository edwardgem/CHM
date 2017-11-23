////////////////////////////////////////////////////
//	Copyright (c) 2006, EGI Technologies, Inc.  All rights reserved.
//
//
//	File:	AttInfo.java
//	Author:	ECC
//	Date:	06/15/06
//	Description:
//		New class to hold Attachment Info.
//
//	Modification:
//		@ECC070307	Option to show only the latest revision of file.
//					The setup is done in PrmProjThread.setRevisionHideShow().
//
////////////////////////////////////////////////////////////////////

package util;

import java.text.SimpleDateFormat;
import java.util.Date;

public class AttInfo
{
	public String attid;
	public String filename;
	public String url;			// for external server file like Google Docs
	public String author;		// owner full name
	public String uid;			// owner id
	public String dateS;
	public String dept;
	public String shareIds;		// list of userids that share this attachment
	public int frequency;		// view number of attachment
	public boolean bShow;		// @ECC070307
	public boolean bLink;		// it is a link file
	private static final SimpleDateFormat df = new SimpleDateFormat ("MM/dd/yy");

	public AttInfo(String aid, String fname, String urlLink, String userid, String au, Date dt, int freq, String dname, String shares, boolean isLink)
	{
		attid = aid;
		filename = fname;
		url = urlLink;
		author = au;
		uid = userid;
		dateS = df.format(dt);
		frequency = freq;
		dept = dname;
		shareIds = shares;
		bShow = true;		// after PrmProjThread.setUpPlan(), only latest revision's bShow is true
		bLink = isLink;
	}
}
